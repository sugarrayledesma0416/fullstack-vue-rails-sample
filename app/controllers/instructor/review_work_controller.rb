class Instructor::ReviewWorkController < RequireInstructorController
  helper MaestroActivityEngine::ActivitiesHelper

  include HasHelp
  include PopupRequestable
  include Uploadable::Controller
  include Instructor::SmartbookAudioPlayback
  include CartridgeViewable
  include GradePassback

  before_action :contextual_help_url
  before_action :assign_recording_server_url, only: :edit
  before_action :assign_allowed_file_types, only: :edit
  before_action :assign_presenter, only: %i[edit update]

  def edit
    @page_title = 'Review student work'
    @angular_controller = 'instructorActivityRequestsCtrl'
    @return_to = vhl_return_to_sanitizer(params[:return_to])
    @return_to_label = params[:return_label] || (session[:activity_return] && session[:activity_return]['label']) || 'Return'
    @view_type = params[:view_type]
    @popup = params[:popup]
    @show_correct_answers = true
    @activity = @presenter&.activity || activity

    if @presenter.current_student_attempt.results.nil?
      begin
        raise "Results missing for completed attempt(##{@presenter.current_student_attempt.id})."
      rescue Exception => e
        VHLMonitor.notify(e)
      end
      flash[:error] = "We're sorry. The results for this activity are unavailable.
                        Need access to these results?
                        Contact technical support at ts@vistahigherlearning.com."
      redirect_to @return_to
    else
      if @presenter.has_rubric?
        @user_scores_for_rubric_grading = UserScoresForGrading.new(@presenter, params, recording_configuration_instance)
        @user_scores_json = @user_scores_for_rubric_grading.score_list.to_json
        @comment_boxes = @user_scores_for_rubric_grading.comment_boxes
      end
      assign_lossless_auth_token if @presenter.assign_lossless_auth_token?
      render layout: 'wizard_layout'
    end
  end

  def assign_recording_server_url
    @recording_server_url = recording_configuration_instance.server_host
  end
  private :assign_recording_server_url

  def update
    @return_to = vhl_return_to_sanitizer(params[:return_to])
    @view_type = params[:view_type]
    @popup = request_from_popup?

    stash_presubmission_score

    grading_params = params.merge(cartridge_params: cartridge_grade_params)
    submission = InstructorGradingSubmission.new(
      current_user,
      @presenter.activity,
      @presenter.students_to_submit,
      @presenter.questions_to_grade,
      @presenter.feedback,
      @presenter.attempts_by_user_id,
      grading_params
    )
    submission.process_submission

    if submission.has_not_sent_notifications? && score_changed?
      @presenter.activity.create_changed_earned_points_notification(
        activity: @presenter.activity,
        new_points_earned: score.points_earned.to_f,
        old_points_earned: @old_points_earned,
        points_possible: score.points_possible,
        section: @presenter.section,
        user: @presenter.current_student
      )
    end

    if @view_type == 'student'
      student_details_params = {
        program_id: current_program.id,
        section_id: @presenter.section.id,
        id: @presenter.current_student.id
      }
      student_details_params.merge!(popup: 1) if @popup
      return redirect_to(gradebook_student_details_path(student_details_params))
    end
    redirect_to(@return_to)
  end

  private

  def stash_presubmission_score
    @old_points_earned = @presenter.score.points_earned
  end

  def score_changed?
    @presenter.score_reload
    @old_points_earned != @presenter.score.points_earned
  end

  def assign_presenter
    current_student = score.user
    current_student_attempt = Attempt.active.by_student_section_and_activity(
      current_student, score.section, score.activity
    ).first

    attempts = { current_student_attempt: current_student_attempt }
    @presenter = ReviewWorkPresenter.new(current_user, score, attempts)
  end

  private def activity
    @activity ||= Activity.find(score.activity_id)
  end

  private def score
    @score ||= GradebookEngine::GradebookAPI.find_score(**safe_score_params_hash)
  end

  def safe_score_params_hash
    params.permit(:activity_id, :section_id, :user_id).to_h.symbolize_keys
  end
end
