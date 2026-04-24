class Instructor::MixAndMatchAssessmentsController < RequireInstructorController
  helper MaestroActivityEngine::ActivitiesHelper

  def index
    presenter = MixAndMatchAssessmentPresenter.new(
      course_id: @course.id,
      current_assessment_id: params[:current_assessment_id],
      lesson_id: params[:lesson_id],
      program_id: params[:program_id],
      current_user:
    )
    render json: presenter.activity_data.to_json
  end

  def show
    @activity = Activity.unscoped.find(params[:id])
    if @activity.question_bank?
      @activity.question_bank_revision_id = QuestionBank.find(@activity.id).current_live_revision.id
    end
    render layout: nil
  end
end
