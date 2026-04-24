class Instructor::GradingStylesController < RequireInstructorController
  helper MaestroActivityEngine::ActivitiesHelper

  include AI::EventTracking
  include HasHelp
  include SmartbookActivityViewable
  include CartridgeViewable

  before_action :contextual_help_url

  def index
    @presenter = InstructorGradingStylesPresenter.new({
      :program => current_program,
      :instructor => current_user,
      :focus => current_focus,
      :activity_id => params[:activity_id],
      :task_type => params[:task_type]
    })

    if @presenter.valid?
      @section = @presenter.section     # required by activity view and partials
      @section_id = @section.id  #required by activity external_reference partial
      @activity = @presenter.activity   # required by activity view and partials
      @section_id = @section.id  #required by activity external_reference partial
      @activity_list_header = @presenter.activity_list_header # required to display header
      @classwork = @presenter.classwork # required to display due date
      @attempt = @presenter.attempt     # required to display strictness
      @attempt_track = @presenter.attempt_track # required to display num attempts allowed.
      @activity_presenter = StudentActivityPresenter.new(@activity, current_user, @section)
      @lesson_header = @activity_presenter.lesson_header
      @allowed_file_types = ''

      # Set referer path to return to after grading.
      session[:grading_done_return_to] = request.referer

      if @activity.smart_book?
        # Make the smartbook unsubmittable.
        assign_santillana_book_iframe_src(max_attempts: 0)
      end

      if current_user.can_use_ai_grading_suggestions? && ai_grading_activity?
        track_ai_grading_event('Grading Styles Entry AI Setting', tracking_data)
      end

    else
      VHLMonitor.notify(StandardError.new(@presenter.error_messages), :rack_env => request.env)
      if current_program
        flash[:error] = "Some user data inconsistency was detected. You were redirected to the dashboard. Please try the previous action after some time."
        redirect_to instructor_dashboard_path(current_program)
      else
        redirect_to ua_home_path
      end
    end
  end

  def update
    previous_ai_state = current_user.ai_grading_suggestions_enabled?
    current_user.update(safe_update_params)

    unless previous_ai_state == current_user.ai_grading_suggestions_enabled?
      track_ai_grading_event('Grading Styles Toggle AI Setting', tracking_data)
    end

    render layout: false
  end

  private def ai_grading_activity?
    @activity.composition? || @activity.open_ended?
  end

  private def tracking_data
    {
      user: current_user,
      section: current_section,
      extra: { state: "toggled_#{current_user.ai_grading_suggestions_enabled? ? 'on' : 'off'}" }
    }
  end

  private def safe_update_params
    params[:instructor].permit(
      :show_auto_graded_questions,
      :grading_style,
      :enable_ai_grading_suggestions
    )
  end
end
