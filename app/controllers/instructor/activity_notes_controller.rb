class Instructor::ActivityNotesController < RequireInstructorController
  CONTENT_ATTRIBUTES = %i[
    body_text note_type recording_path title video_recording_path
  ].freeze
  LOCATION_ATTRIBUTES = %i[activity_id cms_revision_id note_item_id].freeze

  skip_before_action :assign_course_sections_and_students_from_focus
  before_action :assign_activity_note, only: %i[update destroy]

  def index
    notes = current_user.activity_notes.by_activity(params[:activity_id])
    render json: notes.to_json
  end

  def create
    note = current_user.activity_notes.create!(
      extract_from_params(CONTENT_ATTRIBUTES + LOCATION_ATTRIBUTES).merge(
        focused_course: current_focus.course, program: current_program
      )
    )
    render json: note, status: :ok
  rescue StandardError => e
    render json: e.message.to_json, status: :unprocessable_entity
  end

  def update
    @note.update!(extract_from_params(CONTENT_ATTRIBUTES))
    render json: @note, status: :ok
  rescue StandardError => e
    render json: e.message.to_json, status: :unprocessable_entity
  end

  def destroy
    @note.destroy
    head :ok
  end

  private def activity_note_params
    params.permit(
      :activity_id,
      :body_text,
      :cms_revision_id,
      :note_item_id,
      :note_type,
      :recording_path,
      :title,
      :video_recording_path
    )
  end

  private def extract_from_params(attributes)
    activity_note_params.slice(*attributes)
  end

  private def assign_activity_note
    @note = current_user.activity_notes.find(params[:id])
  end
end
