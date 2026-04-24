class StudyPlanConceptsController < ApplicationController
  include StudyPlanPresenterSetup

  before_action :require_user, :require_program_access

  def index
    @presenter = StudyPlanConceptsPresenter.new(current_program.id, current_user.id)
  end

  def show
    @activity = Activity.find(params[:id])
    @current_program = @activity.program
    attempt = Classwork.new(current_user, current_section_id).find_or_new_attempt(@activity)
    @presenter = get_study_plan_presenter(attempt)
    @section = current_section
    @return_url = BestDefaultPath.best_default_path(
      current_user, current_program, @section, session
    )
    if @presenter.show_study_plan? && @presenter.study_plan_version == 'v1'
      render :show
    else
      flash[:notice] = @presenter.redirect_notice
      redirect_to section_activity_path(@section.id, @activity.id)
    end
  end
end
