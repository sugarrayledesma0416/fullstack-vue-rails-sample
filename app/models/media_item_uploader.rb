class MediaItemUploader
  include Uploadable::Controller
  include Radner::FilesS3Bucket

  attr_accessor :uuid, :uploaded_file, :uploaded, :errors

  def initialize(params)
    self.uuid = params[:qquuid]
    self.uploaded_file = params[:qqfile]
    self.uploaded = false
    self.errors = []
  end

  def upload
    scan_for_virus
    validate if upload_is_virus_free?
    upload_file_to_temp
    self
  end

  private def scan_for_virus
    process_uploaded_file(uploaded_file, needs_filetype = false)
    unless upload_is_virus_free?
      errors << set_detected_virus_error_if_detected(error_type = :text)
    end
  end

  private def upload_file_to_temp
    if valid?
      self.uploaded = upload_file(uploaded_file)
    end
  end

  def validate
    errors << "Your file has no size" if uploaded_file.size == 0
    errors << "The path to your file could not be found" if uploaded_file.path.blank?
    errors << "Your file's name is blank" if file_basename.blank?
  end

  def valid?
    errors.empty?
  end

  def result
    if uploaded?
      { temp_file_path: s3_temp_file_path,
        original_filename: uploaded_file.original_filename,
        success: uploaded }
    else
      { errors: errors.join("\n"),
        temp_file_path: s3_temp_file_path,
        original_filename: uploaded_file.original_filename,
        success: uploaded }
    end
  end

  private def file_basename
    File.basename(uploaded_file.original_filename, ".*")
  end

  private def s3_temp_file_path
    File.join('tmp', 'uploads', "#{uuid}.tmp").to_s
  end
  alias_method :file_path, :s3_temp_file_path

  private def uploaded_file_path
    uploaded_file.path
  end

  def uploaded?
    uploaded
  end

  private def s3_profile_name
    M3::Application.config.instructor_media_profile
  end

  private def s3_bucket_name
    M3::Application.config.instructor_media_bucket_name
  end
end
