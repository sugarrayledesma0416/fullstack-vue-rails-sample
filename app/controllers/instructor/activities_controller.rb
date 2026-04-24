class Instructor::ActivitiesController < RequireInstructorController
  helper MaestroActivityEngine::ActivitiesHelper

  include ActivityViewable
  include HasHelp
  include StudyPlanPresenterSetup
  before_action :hide_header

  def show
    @activity = Activity.find(params[:id]).extend(ActivityViewDecorator)
    @student = Student.find(params[:user_id])
    @section = current_section # required by activity view and partials
    @section_id = @section.id # required by activity external_reference partial

    common_prep(params)
    @activity_presenter ||= InstructorActivityPresenter.new(
      @activity, user_for_presenter, current_section, current_focus.course
    )
    check_if_activity_in_study_plan
    @activity_list_header = @activity_presenter.activity_list_header # required to display header
    @attempt = @classwork.find_or_new_attempt(@activity)

    # We need to retrieve the activity with the correct cms revision id
    @activity.ensure_correct_version(@attempt.cms_revision_id)
    @attempt.activity = @activity

    @results = @attempt.results
    @attempt_track = @attempt.attempt_track
    @angular_controller = 'instructorActivityRequestsCtrl'
    @return_label = 'Return to student requests'
    @return_url = instructor_help_requests_path(current_program)
    @lesson_header = @activity_presenter.lesson_header
    @video_settings = @activity_presenter.video_settings # required by learning engine
    current_user.instructor? && @course_policy = CourseLibraryEditPolicy.new(
      current_user, current_focus
    )

    if @activity.santillana?
      assign_santillana_book_iframe_src(max_attempts: @attempt_track.max)
    end

    render "activities/#{@attempt.current_view}", layout: 'layouts/activity'
  end

  private def user_for_presenter
    @student
  end

  # Hide program logo
  private def hide_header
    @hide_header = true
  end

  private def randomize_assessment?
    false
  end
end
