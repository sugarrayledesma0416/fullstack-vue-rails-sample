class Instructor::QuestionBankAssessmentsController < RequireInstructorController
  def index
    presenter = QuestionBankAssessmentPresenter.new(
      lesson_id: params[:lesson_id],
      program_id: params[:program_id]
    )
    render json: presenter.activity_data.to_json
  end
end
