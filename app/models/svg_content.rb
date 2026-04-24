module SvgContent
  include Radner::S3Bucket

  def svg_content
    return unless extension == '.svg'

    # all live content should be on cdn
    # this flag allows temporary read redirection to a local file
    # for development or testing purposes
    if cdn?
      cdn = SvgCache.new(cache_connection, s3_bucket)
      content = cdn.svg_get(cache_key, content_filepath)
      VHLMonitor.notify(cdn.cache_error) if cdn.cache_error
      content
    else
      filepath = "public#{public_filename}"
      File.read(filepath) if File.exist?(filepath)
    end
  end

  def content_filepath
    cdn_target_filename[1..]
  end

  private def cache_key
    "svg:#{content_filepath}"
  end

  def remote_content_exist?
    s3_bucket.file_exist?(content_filepath)
  end

  private def cache_connection
    M3::Application.config.cdn_cache
  end

  private def s3_profile_name
    M3::Application.config.s3_media_profile_name
  end

  private def s3_bucket_name
    M3::Application.config.s3_media_bucket_name
  end
end
