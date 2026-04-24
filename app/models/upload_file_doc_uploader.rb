class UploadFileDocUploader
  include Radner::FilesS3Bucket
  include UploadFileActivityS3Config

  USER_UPLOADS_PATH = 'instructor_activity_uploads'.freeze
  attr_accessor :file_name

  def initialize(user)
    @user = user
  end

  def upload(params)
    file_uploader = FileUploader.new(params).upload
    file_uploader_results = file_uploader.result
    self.file_name = file_uploader_results[:original_filename]
    if file_uploader_results[:success]
      final_file_path = create_destination_path(
        file_uploader.uuid, sanitize_file_name
      )
      s3_bucket.move_file(file_uploader_results[:temp_file_path], final_file_path)
      return upload_response(file_uploader_results, final_file_path)
    end
    file_uploader_results
  end

  def delete_file(file_path)
    bucket_result = s3_bucket.delete_file(file_path)
    bucket_result
  end

  def get_signed_url(file_path)
    FileUploadUrl.new(relative_url: file_path).signed_url
  end

  private def create_destination_path(file_uuid, original_filename)
    File.join(
      USER_UPLOADS_PATH,
      @user.id.to_s,
      file_uuid,
      original_filename
    ).to_s
  end

  private def upload_response(file_uploader_results, final_file_path)
    {
      success: true,
      original_filename: file_uploader_results[:original_filename],
      final_file_path: final_file_path,
      signed_url: FileUploadUrl.new(relative_url: final_file_path).signed_url
    }
  end
end
