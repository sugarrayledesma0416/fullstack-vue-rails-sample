#  encoding: utf-8

class MediaItemPublishProcessor
  include BasePublishProcessor

  attr_accessor :payload_tempfile_path

  VALID_ATTRIBUTES = %i[
    alt_tag
    asset_path
    cdn
    filename
    height
    id
    media_type
    long_description
    payload_tempfile_path
    revision_id
    size
    transcript
    width
  ].freeze

  REQUIRED_ATTRIBUTES = %i[
    filename
    id
    media_type
    size
  ].freeze

  def initialize(params)
    self.payload_tempfile_path = params.delete('payload_tempfile_path')
    super(MediaItem, params)
  end

  def cdn?
    # coersion of cdn value necessary to make cukes pass
    request['cdn'].present? && request['cdn'].to_s === 'true' # This value is true when when published media item uses content delivery network
  end
  private :cdn?

  def vocab_list?
    request['media_type'].to_s === 'vocab_list'
  end
  private :vocab_list?

  def validate_params
    super
    validate_tempfile_path unless cdn?
    validate_program_id if vocab_list?
  end
  private :validate_params

  def perform
    unless errors.present?
      create_or_update_publishable
      unless cdn?
        retriever = MediaFileRetriever.new(payload_tempfile_path, request['size']).retrieve
        if retriever.result && object_to_publish.payload = retriever.result
          DefaultVocabWordsReplacer.new(object_to_publish.full_filename, request['program_id']).replace if vocab_list?
        else
          self.errors << retriever.error
        end
      end
      set_status_and_errors
    end
  end
  private :perform

  def validate_tempfile_path
    # Adds an error when media item is not in cdn and no payload tempfile path is set
    self.errors << 'Payload tempfile path is required' if payload_tempfile_path.blank?
  end
  private :validate_tempfile_path

  def validate_program_id
    # Adds an error when media item is vocab list but does not specify a program to associate to
    self.errors << 'Program id for vocab lists is required' if request['program_id'].blank?
  end
  private :validate_program_id

  class MediaFileRetriever
    attr_accessor :file_path, :requested_size, :result, :error

    def initialize(file_path, requested_file_size)
      self.file_path = file_path
      self.requested_size = requested_file_size
    end

    def retrieve
      self.result = remote_response.body if successful?
      self
    end

    def error
      'Connection failed' if request_failed?
    end

    def successful?
      error.nil?
    end
    private :successful?

    def remote_response
      return @response if defined?(@response)
      raise "Invalid url for file retrieval." unless file_path.include? 'https://'

      file_uri = URI.parse(file_path)
      @response = Net::HTTP.start(file_uri.host,
                                  file_uri.port,
                                  use_ssl: file_uri.scheme == 'https') do |http|
        http.get(file_uri.path)
      end
    end
    private :remote_response

    def request_failed?
      remote_response.code != '200'
    end
    private :request_failed?

    def file_correct_size?
      remote_response.header['content-length'].to_i == requested_size.to_i
    end
  end
end


