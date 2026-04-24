module Media
  class StudentUploadsController < ApplicationController
    before_action :require_user

    def create_svr_video
      results = uploader.upload(params)
      render plain: results.to_json
    end

    def delete_svr_video
      render plain: {
        success: uploader.delete_video(params[:uuid], params[:delete_file_path])
      }.to_json
    end

    private def uploader
      @uploader ||= SoloVideoRecordingUploader.new(current_user)
    end
  end
end
