module ActivityContent
  attr_accessor :content_object
  attr_reader :revision_id, :content

  attr_writer :content_json

  include Radner::S3Bucket

  def content_object
    return @content_object if defined?(@content_object)
    @content_object = parse_content

    log_parse_warnings if @content_object && parse_warnings.any?

    @content_object
  end

  def cdn?
    !!@cdn
  end

  def content
    # all live content should be on cdn
    # this flag allows temporary read redirection to a local file
    # for development or testing purposes
    if cdn?
      cdn = ActivityCache.new(cache_connection, s3_bucket, ::STATS_PROXY)
      content = cdn.activity_get(cache_key, content_filepath)
      VHLMonitor.notify(cdn.cache_error) if cdn.cache_error
      content
    else
      File.read(content_filepath) if File.exist?(content_filepath)
    end
  end

  def content_filepath
    Activity.filepath_from_revision_id(revision_id, instructor_created?, cdn?)
  end

  def parse_errors
    @parser&.errors || []
  end

  def parse_warnings
    @parser&.warnings || []
  end

  def log_parse_warnings
    parse_warnings.select(&:deprecation?).each do |warning|
      Rails.logger.warn("#{warning.message} (ID:#{@activity_id} L:#{warning.line})")
    end
  end

  def cache_key
    "#{cache_key_prefix}:#{revision_id}"
  end
  private :cache_key

  def cache_key_prefix
    raise NotImplementedError
  end

  def content=(content)
    store_content(content)
  end

  # this is used for InstructorGeneratedContent (IGC) or when
  # the publish payload contains xml content in the non-live environment
  def store_content(new_content)
    return if content_json

    if Rails.env.live?
      store_remote_file_contents(content_filepath, new_content)
    else
      store_file_contents(content_filepath, new_content)
    end
  end

  def store_file_contents(filepath, new_content)
    unless File.exist?(filepath) # no overwrites!
      FileUtils.makedirs(File.dirname(filepath))
      File.write(filepath, new_content)
    end
  end
  private :store_file_contents

  def store_remote_file_contents(content_filepath, new_content)
    unless remote_content_exist? # no overwrites!
      s3_bucket.store_file_contents!(content_filepath, new_content)
    end
  end
  private :store_remote_file_contents

  def remote_content_exist?
    s3_bucket.file_exist?(content_filepath)
  end

  def parse_content_xml(content_arg = nil, program = nil)
    @parser = MaestroActivityEngine::ActivityParser.create_parser(
      content_arg || content,
      MediaLink,
      program
    )
    # returns a content_object on success, nil on failure
    @parser.parse
  end
  private :parse_content_xml

  def cache_connection
    M3::Application.config.cdn_cache
  end
  private :cache_connection

  def s3_profile_name
    M3::Application.config.s3_activity_profile_name
  end
  private :s3_profile_name

  def s3_bucket_name
    M3::Application.config.s3_activity_bucket_name
  end
  private :s3_profile_name
end
