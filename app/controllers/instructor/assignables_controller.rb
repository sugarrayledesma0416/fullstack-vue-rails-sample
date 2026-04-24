class Instructor::AssignablesController < RequireInstructorController
  skip_before_action :assign_course_sections_and_students_from_focus

  def index
    translate_params_for_assignment_wizard!(:selected_activities, :activity_ids)
    translate_params_for_assignment_wizard!(:selected_resources, :resource_ids)

    if params[:activity_ids].blank? && params[:resource_ids].blank?
      flash[:error] = 'There was an error processing your request. Please try again.'
      redirect_to instructor_toc_path(current_program)
    else
      @presenter = InstructorAssignablesPresenter.new(
        current_focus,
        params.merge(
          preferred_assignment_date: session[:preferred_assignment_date]
        )
      )
      render layout: false
    end
  end

  private def translate_params_for_assignment_wizard!(from, to)
    params[to] = []
    params[to] = params[from].split(',').map(&:to_i) if params[from]
  end
end
