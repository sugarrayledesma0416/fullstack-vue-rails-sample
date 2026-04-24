class Instructor::AssessmentTimeLimitsController < RequireInstructorController
  before_action :require_section_focus, only: :index
  skip_before_action :set_current_focus, only: :update_time_limits
  skip_before_action :assign_course_sections_and_students_from_focus,
                     only: :update_time_limits

  def index
    @presenter = StudentTimeLimitsPresenter.new(section_id: params[:section_id],
                                                activity_id: params[:activity_id])
    @return_to = request.referrer

    render partial: 'set_times_modal', format: :html
  end

  def update_time_limits
    @presenter = StudentTimeLimitsPresenter.new(section_id: params[:section_id],
                                                activity_id: params[:activity_id],
                                                time_limit: params[:time_limit].to_unsafe_hash)

    if @presenter.process_time_limits
      head :ok
    else
      render json: @presenter.errors, status: :unprocessable_entity
    end
  end

  def require_section_focus
    return unless current_focus.type == 'course'
    flash[:error] = 'You must be focused on a Section in your course to view the requested page.'
    redirect_to instructor_assessments_path
  end
end
