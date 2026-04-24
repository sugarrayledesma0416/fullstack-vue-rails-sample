module Media
  class InstructorUploadsController < ApplicationController
    before_action :require_user
    before_action :delete_s3_file, only: [:create_file], if: :replace_file?

    def create_file
      results = uploader.upload(params)
      render plain: results.to_json
    end

    def delete_uploaded_file
      render plain: { success: delete_s3_file }.to_json
    end

    private def delete_s3_file
      delete_params = deleted_file_params
      uploader.delete_file(
        delete_params[:file_path]
      )
    end

    def file_signed_url
      signed_url_params = file_signed_url_params
      signed_url = uploader.get_signed_url(
        signed_url_params[:file_path]
      )
      render plain: {
        success: true,
        signed_url: signed_url
      }.to_json
    end

    private def replace_file?
      params['upload_type'] == 'replace'
    end

    private def uploader
      @uploader ||= UploadFileDocUploader.new(current_user)
    end

    private def deleted_file_params
      params.permit(:file_path)
    end

    private def file_signed_url_params
      params.permit(:file_path)
    end
  end
end
