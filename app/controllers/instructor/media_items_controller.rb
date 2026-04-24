class Instructor::MediaItemsController < ApplicationController
  before_action :require_user
  before_action :require_instructor

  def create
    media_item = InstructorMediaItem.create!(
      instructor_id: current_user.id,
      media_type: 'audio',
      original_filename: params[:filename],
      temp_file_path: "instructor_created/in_progress_uploads/#{params[:filename]}"
    )

    render json: { id: media_item.id, url: media_item.public_filename }.to_json
  end

  def update
    media_item = InstructorMediaItem.find(params[:id])
    media_item.update!(transcript: params[:transcript])
    head :ok
  end
end
