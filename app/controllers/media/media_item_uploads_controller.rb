module Media
  class MediaItemUploadsController < ApplicationController
    before_action :upload_image, only: %i[create_image]

    def create_image
      if @uploader.result[:success]
        render plain: parse_image_reference.to_json
      else
        render plain: @uploader.result.to_json
      end
    end

    # POST /media/create_assessment_recording
    # Creates a new audio recording or video recording.
    # @param recording_path [String] recording location
    # @param recording_type [String] video_recording / audio
    # @return [JSON] recording id and media type.
    def create_assessment_recording
      result = InstructorCreatedActivity::Reference.new(
        recording_path: params[:recording_path],
        type: params[:recording_type],
        id: ''
      )
      result.send("parse_#{params[:recording_type]}".to_sym)
      render plain: result.to_json
    end

    private def parse_image_reference
      InstructorCreatedActivity::Reference.new(
        instructor_id: current_user.id,
        temp_file_path: @uploader.result[:temp_file_path],
        original_filename: @uploader.result[:original_filename],
        type: 'image'
      ).parse_image.merge(success: true)
    end

    private def upload_image
      @uploader = ImageUploader.new(params).upload
    end
  end
end
