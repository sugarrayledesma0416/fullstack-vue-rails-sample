class Instructor::MixAndMatchCreatedActivitiesController < RequireInstructorController
  def index
    presenter = MixAndMatchCreatedActivityPresenter.new(
      course_id: current_focus.course.id,
      lesson_id: params[:lesson_id],
      program_id: params[:program_id],
      created_activity_id: params[:created_activity_id]
    )
    render json: presenter.activity_data.to_json
  end
end
