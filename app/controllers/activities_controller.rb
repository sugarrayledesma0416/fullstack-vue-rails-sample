# Require instructor/activities controler in order to avoid warning:
# toplevel constant ActivitiesController referenced by
# Instructor::ActivitiesController, which is caused when we render views that
# contain this line:
# <% if controller.is_a?(::ActivitiesController) ||
#       controller.is_a?(Instructor::ActivitiesController) %>
# See:
# https://blog.jetbrains.com/ruby/2017/03/why-you-should-not-use-a-class-as-a-namespace-in-rails-applications/
# TODO: Change the controllers so they assign some instance variable that
#       can be checked instead, but should first figure out which actions
#       actually need it.
require 'instructor/activities_controller'

class ActivitiesController < ApplicationController
  helper MaestroActivityEngine::ActivitiesHelper

  include ActivityViewable
  include Uploadable::Controller
  include HasHelp
  include PopupRequestable
  include CartridgeViewable
  include StudyPlanPresenterSetup
  include ActivityRubric
  include PartnerChatHelper
  include GradePassback

  before_action :require_user, :contextual_help_url

  include SectionHeader

  before_action :assign_section_header, only: %i[show submit]
  before_action :prevent_access_when_enrollment_locked

  before_action :set_activity_by_id, only: %i[
    answer_keys
    diagnostic_feedback
    export_portfolio
    finalize
    next_activity
    permalink
    practice
    re_try
    save
    show
    submit
    submit_nongradable
    update_time_spent
    vocab_tutorial_iframe
  ]

  before_action :set_activity_by_cms_activity_id, only: %i[popup popup_submit]
  before_action :assign_activity_and_rubric_presenter, only: %i[rubric scored_rubric]

  before_action :set_current_program, only: %i[
    answer_keys
    diagnostic_feedback
    finalize
    permalink
    popup
    practice
    re_try
    save
    show
    submit
    update_time_spent
    vocab_tutorial_iframe
    export_portfolio
  ]

  before_action :ensure_correct_family, only: %i[show]

  before_action :require_program_access,
                only: %i[show submit re_try save practice finalize permalink answer_keys popup]
  before_action :warn_insufficient_course_access, only: %i[show], unless: :has_grace_period?
  before_action :ensure_correct_section, only: %i[show popup], if: :current_user_is_student?

  before_action :set_current_focus,
                except: %i[swf image recording smartbook_resume_time_tracking rubric],
                if: :current_user_is_instructor?
  before_action :assign_activity_presenter,
                only: %i[
                  show
                  submit
                  re_try
                  save
                  practice
                  finalize
                  popup
                  popup_submit
                  export_portfolio
                ]
  before_action :set_assignment_validator, only: %i[show]
  before_action :set_guid_viewer_mode, only: %i[show]
  before_action :assign_video_settings,
                only: %i[show submit re_try save practice finalize popup popup_submit]
  before_action :assign_show_correct_answers,
                only: %i[show submit re_try save practice finalize]

  before_action :require_instructor_or_grader,
                only: %i[answer_keys scored_rubric]
  before_action :log_time_spent_error_cases,
                only: %i[submit re_try save update_time_spent]
  before_action :ensure_can_access_activity,
                except: %i[swf vocab_tutorial_iframe image recording smartbook_resume_time_tracking]
  before_action :require_chat_enabled,
                if: :chat_activity?,
                only: %i[show submit re_try save practice next_activity finalize permalink]
  before_action :require_ai_virtual_chat_enabled,
                if: :ai_virtual_chat_activity?,
                only: %i[show submit re_try save practice next_activity finalize permalink]

  before_action :assign_course_policy

  after_action :dismiss_notifications, only: %i[show]
  after_action :auto_export_portfolio_after_submit, only: %i[submit]
  before_action :hide_header
  before_action :set_page_header

  def set_page_header
    # If the activity is nil _or_ its title is nil, set a generic page header.
    # This is to avoid interpolating an empty string after the dash below.
    #
    # NOTE: the safe-navigation operator is necessary only within this if-clause
    # because the clause ensures that the method will return early whenever
    # `activity` is nil.
    if activity&.title.nil?
      @page_header = 'Activities Content'
      return
    end

    context_prefix = activity.assessment? ? 'Assessments' : 'Activities'
    @page_header = "#{context_prefix} - #{strip_html_tags(activity.title.to_s)}"
  end

  # Hide program logo
  def hide_header
    @hide_header = true
  end
  private :hide_header

  private def set_guid_viewer_mode
    @activate_guid_viewer = params[:activate_guid_viewer] == 'true'
  end

  def show
    if skip_to_practice_mode?
      practice(practice_layout)
    else
      process_show_activity(@activity_presenter) do
        respond_to do |format|
          format.html { show_activity(params) }
        end
      end

      flash[:notice] = @activity_presenter.flash_notice if @activity_presenter.flash_notice.present?
    end
  end

  def permalink
    # gotta love typechecking
    section = (current_user.student? && current_user.current_section_in_program(current_program)) ||
              Section.section_zero
    session[:is_popup_via_vtext] = true
    redirect_to popup_section_activity_path(section,
                                            @activity.cms_activity_id,
                                            program_id: @activity.program)
  end

  def popup
    @is_popup = true
    params[:id] = @activity.id
    @activity_via_vtext = true if session[:is_popup_via_vtext]
    session.delete(:is_popup_via_vtext)
    check_if_activity_in_study_plan
    @no_activity_footer = true unless @activity.gradable?
    @show_vocab_footer = @activity.content_object.present? &&
                         (@activity.content_object.audio_reference_media_item.present? ||
                          @activity.content_object.vocablist_content?)

    # Extracted to private method be able to override in Spr::ActivitiesController
    render_popup_show
  end

  def popup_submit
    @is_popup = true
    set_activity_list_header
    submit('layouts/activity_popup')
  end

  def popup_practice
    @is_popup = true
    practice('layouts/activity_popup')
  end

  def next_activity
    classwork = Classwork.new(current_user, current_section_id)
    workset = classwork.current_workset(activity)
    next_activity = workset.next_activity(activity) if workset

    if next_activity && next_activity != Workset::LAST_ACTIVITY
      redirect_to section_activity_path(current_section_id, next_activity.id)
    else
      redirect_to section_toc_path(current_section_id, activity.program)
    end
  end

  def re_try(layout = 'layouts/activity')
    set_activity_list_header
    common_prep(params) do
      @attempt = @classwork.find_or_new_attempt(@activity)
      @activity.ensure_correct_version(@attempt.cms_revision_id)
    end

    @attempt = @classwork.find_active_attempt(@activity) # must be an active attempt to re-try
    if @attempt
      @attempt.activity = @activity  # ensure attempt.activity points to the same object
      @attempt.add_time_spent(params[:start_time].to_i, time_now_in_seconds)
      @attempt.propagate_time_spent_to_score

      @attempt_track = @attempt.attempt_track
      @results = @attempt.results

      set_show_not_enrolled_warning
      render(:submit, layout:)
    else
      flash.now[:error] = active_attempt_error_message
      show_activity(params)
    end
  end

  def save(layout = 'layouts/activity')
    set_activity_list_header
    assign_allowed_file_types
    common_prep(params) do
      @attempt = @classwork.find_or_new_attempt(@activity)
      @activity.ensure_correct_version(@attempt.cms_revision_id)
      @attempt.activity = @activity  # ensure attempt.activity points to the same object
    end
    save_state(layout)
  end

  def submit(layout = 'layouts/activity')
    case params[:commit]
    when 'Re-try'
      re_try
    when 'Accept'
      finalize
    else
      set_activity_list_header
      assign_allowed_file_types
      common_prep(params) do
        @attempt = @classwork.find_or_new_attempt(@activity)
        @activity.ensure_correct_version(@attempt.cms_revision_id)
        @attempt.activity = @activity  # ensure attempt.activity points to the same object
      end

      assign_lossless_auth_token if @activity.ai_virtual_chat?

      # if complete, we don't want to re-open attempts if the student
      # uses the Back button and re-submits.
      # this is not the case for instructors however we want to be able submit
      # even when the attempt already has been completed

      if @attempt.complete? && !@attempt.user.instructor?
        @activity_submittable = false
        # This variable is assigned in common_prep.
        @transcript_settings.show_transcripts = true

        assign_score_from_gradebook_engine

        @results = @attempt.validate_responses(
          @activity,
          activity_params_hash.merge(@attempt.stored_responses),
          request.env
        )
        # This is needed in order for the PartnerChatRecording record to
        # be inside the results, rather than just a hash.
        @results = @attempt.results if video_chat_recording?
        @attempt_track = @attempt.attempt_track
        render(:complete, layout:)
      else
        @results = @attempt.validate_responses(
          @activity,
          activity_params_hash,
          request.env
        )
        activity_complete = @attempt.last_possible? || @results.complete?
        @transcript_settings.show_transcripts = activity_complete

        # TODO - Move this logic into a class
        if @activity_presenter.partner_chat?
          partner_chat_submission = PartnerChatSubmission.new(@results, @activity, params)
          partner_chat_submission.prepare_for_submission(activity_complete, time_now_in_seconds)
          @video_path = partner_chat_submission.video_path
          @results = partner_chat_submission.results
        elsif @activity_presenter.solo_video_recording_or_included_in_multipart_activity?
          solo_video_recording_submission = SoloVideoRecordingSubmission.new(@results, @activity, params)
          solo_video_recording_submission.prepare_for_submission(activity_complete, time_now_in_seconds)
          @video_path = solo_video_recording_submission.video_path
          @results = solo_video_recording_submission.results
        elsif @activity_presenter.group_chat?
          group_chat_submission = GroupChatSubmission.new(@results, @activity, activity_params_hash)
          group_chat_submission.prepare_for_submission(activity_complete, time_now_in_seconds)
          @video_path = group_chat_submission.video_path
          @results = group_chat_submission.results
        end

        begin
          Attempt.transaction do
            @attempt.write_results(@results, activity_complete, 'submitted',
                                   params[:start_time].to_i, time_now_in_seconds)

            if activity_complete
              UserReadingsGenerator.new(
                @activity,
                @results,
                current_section,
                current_user
              ).generate
            end

            make_submission
            assign_score_from_gradebook_engine

            if video_chat_recording?
              # This is needed in order for the recording instance record to be inside the results,
              # rather than just the instance id.
              @results = @attempt.results
            else
              RecordingSaver.new(@activity, current_user, @results).save_recordings
            end
          end

          @attempt_track = @attempt.attempt_track
          set_show_not_enrolled_warning
          if activity_complete
            if auto_export_portfolio?
              # attempt.artifact_sharing_status is set to 'in_progress' in post action hook so
              # its latest value is not available on submitted page. So this variable is used.
              @portfolio_export_in_progress = true
              flash.now[:notice] = 'Activity complete and activity sent to Portfolio.'
            else
              flash.now[:notice] = 'Activity complete.'
            end
            if @activity_presenter.redirect_to_dashboard?(activity_complete) && !request.xhr?
              redirect_to_course_section(@activity_presenter)
            else
              respond_to do |format|
                format.html { render(:complete, layout:) }
                format.json {
                  activity_response = ActivityResponseBuilder.new(@activity, @video_path)
                  render json: activity_response.to_json, status: activity_response.status
                }
              end
            end
          else
            render(:decide, layout:)
          end
        rescue StandardError => e
          VHLMonitor.notify(e, rack_env: request.env)

          # This helps us figure out what went wrong in test/dev environments if this
          # method fails.  Otherwise we just get a flash error but have no clue why.
          Rails.logger.error("#{e.message}\n#{e.backtrace.join("\n -- ")}") unless Rails.env.live?

          flash.now[:error] = 'Your work could not be submitted, please try again later.'
          @attempt_track = @attempt.attempt_track
          render(:show, layout:)
        end
      end
    end
  end

  def rubric
    unless @activity.has_rubric? || @activity.has_external_rubric?
      flash.now[:error] = no_rubric_msg
      return
    end

    set_up_rubric_page
    render layout: 'layouts/music_v1/responsive'
  end

  def scored_rubric
    return flash.now[:error] = no_rubric_msg unless @activity.has_rubric?

    set_up_rubric_page
    render layout: 'layouts/music_v1/responsive', template: 'activities/rubric'
  end

  def export_portfolio
    @rendering_portfolio_artifact = true
    instance_variables_for_portfolio
    if @attempt.escape_artifact_export?
      status = if @attempt.artifact_sharing_status == 'in_progress'
                 :prev_export_in_progress
               else
                 :prev_export_is_success
               end
      render json: { status:, success: false }
    else
      upload_artifacts
      render json: { status: :ok, success: true }
    end
  end

  private def upload_artifacts
    school_id = if current_user.student?
                  current_section.school_id
                else
                  current_focus&.course&.school&.id
                end
    @attempt.attempt_config_attributes = {
      artifact_sharing_status: 'in_progress'
    }
    Portfolio::ArtifactsUploadWorker.perform_async(
      @attempt.id,
      generate_html_for_pdf_artifact,
      html_for_artifact_header,
      html_for_artifact_footer,
      school_id
    )
  end

  private def auto_export_portfolio_after_submit
    return unless auto_export_portfolio?

    begin
      @rendering_portfolio_artifact = true
      upload_artifacts
    rescue StandardError => e
      Rails.logger.error("Portfolio export failed. #{e.message}")
    end
  end

  private def auto_export_portfolio?
    params[:auto_export_portfolio] == 'true' &&
    @attempt&.complete? &&
    !@attempt&.escape_artifact_export?
  end

  private def generate_html_for_pdf_artifact
    render_to_string(
      template: 'activities/portfolio',
      layout: 'portfolio',
      formats: [:html]
    )
  end

  private def html_for_artifact_header
    render_to_string(
      template: 'layouts/_portfolio_pdf_header.html.erb',
      layout: nil
    )
  end

  private def html_for_artifact_footer
    render_to_string(
      partial: 'layouts/portfolio_pdf_footer.html.erb'
    )
  end

  private def instance_variables_for_portfolio
    set_activity_list_header
    assign_allowed_file_types
    common_prep(params) do
      @attempt = @classwork.find_or_new_attempt(@activity)
      @activity.ensure_correct_version(@attempt.cms_revision_id)
      @attempt.activity = @activity  # ensure attempt.activity points to the same object
    end
    if @attempt.complete?
      @activity_submittable = false
      # This variable is assigned in common_prep.
      @transcript_settings.show_transcripts = true

      assign_score_from_gradebook_engine

      @results = @attempt.validate_responses(
        @activity,
        activity_params_hash.merge(@attempt.stored_responses),
        request.env
      )
      # This is needed in order for the PartnerChatRecording record to
      # be inside the results, rather than just a hash.
      @results = @attempt.results if video_chat_recording?
      @attempt_track = @attempt.attempt_track
    end
  end

  def student_and_completed_activity?
    current_user.student? && no_practice_mode? && completed_activity?
  end
  helper_method :student_and_completed_activity?

  private def no_practice_mode?
    params[:action] != 'practice' && !skip_to_practice_mode?
  end

  private def completed_activity?
    Attempt.where(
      activity_id: @activity.id,
      section_id: current_section_id,
      status_code: AttemptStatus::CODE_COMPLETED,
      user_id: current_user.id
    ).exists?
  end

  private def render_answer_keys
    if request_from_popup?
      @is_popup = true
      render layout: 'layouts/activity_popup'
    else
      render layout: 'layouts/activity'
    end
  end

  private def render_popup_show
    show_activity(params, 'layouts/activity_popup')
  end

  private def skip_to_practice_mode?
    return true if params[:practice] == 'true'

    # Students may need to go directly into pratice mode if they're
    # accepting an invitation to partner on an activity that they've
    # already completed.
    ((@activity_presenter&.partner_chat? || @activity_presenter&.group_chat?) &&
      joining_completed_chat?)
  end

  # When coming to this activity by accepting a partner chat invitation,
  # the joinchat param will be set to true.
  # In this case, check to see if they've already got a completed attempt, so
  # we display the activity in practice mode instead of the normal completed view.
  private def joining_completed_chat?
    params[:joinchat] == 'true' && completed_activity?
  end

  private def make_submission
    submission = Gradebook::Submission.new(current_user, current_section, @activity)
    length = if video_chat_recording?
               @attempt.submission_length(@results)
             else
               @attempt.submission_length
             end
    submission.submit(@results, Time.now.utc, @attempt.time_spent, length)
    process_grade_passback(current_user, @attempt)
  end

  private def assign_score_from_gradebook_engine
    # @score will be nil for section zero and for an unassigned submission
    # view helper has a fallback using the mae results object
    @score = if current_section.non_zero?
               GradebookEngine::GradebookAPI.find_student_grade(
                 activity_id: @activity.id,
                 section_id: current_section.id,
                 user_id: current_user.id
               )
             end
  end

  def submit_nongradable
    activity = Activity.find(params[:id]).extend(ActivityViewDecorator)
    # create or update the score record for an ungradable activity
    Gradebook::Submission.new(current_user, current_section, activity).submit_nongradable
    # create or update the attempt record to be marked complete
    attempt = Attempt.create_completed(current_user, activity, current_section)
    process_grade_passback(current_user, attempt)
    head :ok
  end

  def practice(layout = 'layouts/activity')
    common_prep(params)
    @attempt = @classwork.practice_attempt(@activity).extend(AttemptViewDecorator)
    assign_activity_presenter
    assign_video_settings
    set_activity_list_header
    if @attempt
      session[:unlocked_assessments] ||= []
      unless @activity.santillana?
        @results = @attempt.validate_responses(
          @activity,
          activity_params_hash,
          request.env
        )
        @attempt.assign_practice_complete(params[:commit], @results.complete?)
      end

      @attempt_track = @attempt.attempt_track
      assign_allowed_file_types

      # Instructors just see show view without notices.
      view_to_render, notice_message = @attempt.assign_view_and_notice(params[:commit])
      flash.now[:notice] = notice_message if notice_message
      if @activity.santillana?
        assign_lossless_auth_token
        assign_santillana_book_iframe_src(
          max_attempts: -1, # unlimited
          modifiable: false
        )
      elsif @activity.ai_virtual_chat?
        assign_lossless_auth_token
      end
      render(view_to_render, layout:)
    else
      flash.now[:error] = 'Practice mode is allowed only after your assignment is complete!'
      show_activity(params)
    end
  end

  def answer_keys
    common_prep(params)
    # This variable is assigned in common_prep.
    @transcript_settings.show_transcripts = true
    @attempt = Attempt.new(activity: @activity, scoring_ruleset: ScoringRuleset.default)
    @activity_presenter = StudentActivityPresenter.new(@activity,
                                                       current_user,
                                                       current_section,
                                                       answer_key_mode: true)
    flash.now[:notice] = 'Answer key mode. All correct answers will be displayed'
    assign_return_link
    set_activity_list_header

    # Extracted to private method be able to override in Spr::ActivitiesController
    render_answer_keys
  end

  def save_state(layout)
    # attempt_track can be set before saving,
    # and in case the save raises an error
    # the attempt_track will be available to render :show
    @attempt_track = @attempt.attempt_track

    activity_saver = ActivityWorkSaver.new(
      @activity,
      @attempt,
      activity_params_hash,
      request.env
    ).save
    @results = activity_saver.results

    # load attempt into presenter, because the view expects it to be in the presenter.
    @activity_presenter.find_or_create_attempt
    set_show_not_enrolled_warning

    flash.now[:notice] = 'Your changes have been saved.'
    render(:submit, layout:)
  rescue StandardError => e
    VHLMonitor.notify(e, rack_env: request.env)

    # This helps us figure out what went wrong in test/dev environments if this
    # method fails.  Otherwise we just get a flash error but have no clue why.
    Rails.logger.error("#{e.message}\n#{e.backtrace.join("\n -- ")}") unless Rails.env.live?

    flash.now[:error] = 'Your work could not be saved, please try again later.'
    render(:show, layout:)
  end

  def finalize
    common_prep(params) do
      @attempt = @classwork.find_active_attempt(@activity) unless @attempt
      if @attempt
        @activity.ensure_correct_version(@attempt.cms_revision_id)
        @attempt.activity = @activity  # ensure attempt.activity points to the same object
      end
    end

    if @attempt
      if @attempt.mark_as_completed(params[:start_time].to_i, time_now_in_seconds)
        @attempt.propagate_time_spent_to_score
        if @attempt.complete?
          UserReadingsGenerator.new(
            @activity,
            @attempt.results,
            current_section,
            current_user
          ).generate
        end
        flash[:notice] = 'Results finalized'
      else
        flash[:error] = 'Problem finalizing results'
      end
      redirect_to(section_activity_path(current_section_id, params[:id]))
    else
      flash.delete(:notice)
      flash.now[:error] = active_attempt_error_message
      show_activity(params)
    end
  end

  # ajax endpoint to retrieve student answer feedback for the diagnostic sub-activity
  # returns html partial
  def diagnostic_feedback
    common_prep(params) do
      @attempt = @classwork.find_or_new_attempt(@activity)
      @activity.ensure_correct_version(@attempt.cms_revision_id)
      @attempt.activity = @activity  # ensure attempt.activity points to the same object
    end

    @results = @attempt.validate_responses(
      @activity,
      activity_params_hash,
      request.env
    )
    @show_correct_answers = true

    render json: {
      feedback: render_to_string(
        'maestro_activity_engine/activities/interactive_video/_diagnostic',
        layout: false,
        locals: {
          content_object: @activity.content_object.diagnostic.first,
          results: @results,
          attempt: @attempt,
          attempt_complete: true
        }
      ),
      donut_results: @results.donut_data
    }
  end

  def update_time_spent
    common_prep(params)
    @attempt = @classwork.find_or_new_attempt(@activity)
    if @activity.activity_type == 'smart_book'
      Xapi::StatementWriter.update_time_tracking(
        :pause, @attempt, current_user, xapi_state_modifiable?
      )
      @attempt.reload
    else
      @attempt.add_time_spent(params['start_time'].to_i, time_now_in_seconds)
    end
    @attempt.propagate_time_spent_to_score
    head :ok
  end

  def smartbook_resume_time_tracking
    common_prep(params)
    @attempt = @classwork.find_or_new_attempt(@activity)
    if @activity.activity_type == 'smart_book'
      Xapi::StatementWriter.update_time_tracking(
        :resume, @attempt, current_user, xapi_state_modifiable?
      )
    end
    head :ok
  end

  def show_activity(params, layout = 'layouts/activity')
    common_prep(params) do
      # this block will ensure data is set up for the correct activity version
      @attempt = @activity_presenter.find_or_create_attempt.extend(AttemptViewDecorator)
      # When begin_work is passed , mark the attemt as started.
      # begin_work is set when the student click on the begin button before starting
      # asn assessment.
      session[:unlocked_assessments] ||= []
      @attempt.mark_as_started! if params[:begin_work]
      @attempt.activity = @activity
      @attempt.save unless @attempt.id
      @activity.ensure_correct_version(@attempt.cms_revision_id)
    end

    load_custom_rubric

    @attempt_track = @attempt.attempt_track
    @instructor_feedback = @attempt.common_instructor_feedback
    # use || since it could have been forced to true at the begining of the action.
    @is_popup ||= request_from_popup?

    if @attempt_track.max == 0
      unless @classwork.closed_section?
        @classwork.ensure_completed_attempt(@activity)
        process_grade_passback(current_user, @attempt)
      end
      # We do not want to show transcripts for html_reading activities
      # Unless the course setting is to show them
      @transcript_settings.show_transcripts = true unless @activity.activity_type == 'html_reading'
    else
      if @attempt.attempted? || @attempt.saved_values?
        @results = @attempt.results
        #raise "no results were set" unless @results
      else
        @read_only = @classwork.closed_section?
      end
    end

    if @attempt.current_view == :complete
      @activity_submittable = false
      @transcript_settings.show_transcripts = true
    end

    assign_return_link
    set_activity_list_header

    @composition_attachment_id = params[:attachment_id]
    assign_allowed_file_types
    if @attempt.in_completed_view_without_results?
      msg = "We're sorry. The results for this activity are unavailable.
              Need access to these results?
              Contact technical support at ts@vistahigherlearning.com."
      begin
        raise "Results missing for completed attempt(##{@attempt.id})."
      rescue Exception => e
        VHLMonitor.notify(e)
      end
      flash[:error] = msg
      redirect_to safe_local_uri(@return_url)
    else
      if @activity.santillana?
        assign_lossless_auth_token # defined in application controller
        assign_santillana_book_iframe_src(max_attempts: @attempt_track.max)
      elsif @activity.ai_virtual_chat?
        assign_lossless_auth_token
      end

      set_show_not_enrolled_warning
      render(@attempt.current_view, layout: layout_for_show_activity(layout))
    end
  end
  private :show_activity

  private def layout_for_show_activity(layout)
    if @is_popup
      spr? ? 'layouts/spr_activity_popup' : 'layouts/activity_popup'
    else
      spr? ? 'layouts/spr_activity' : layout
    end
  end

  def set_activity_list_header
    @activity_list_header = @activity_presenter.activity_list_header
    @lesson_header = @activity_presenter.lesson_header
  end
  private :set_activity_list_header

  private def active_attempt_error_message
    'There was a problem recording your submission.<br/>' \
    "Your #{instructor_label} may have reset your work. " \
    'Please re-submit to complete your assignment.'
  end

  def prevent_access_when_enrollment_locked
    # argh, current_user.student? doesnt work, because the default value for a user is 'Student'
    enrollment = current_user.instance_of?(Student) && current_user.active_enrollment_by_section(current_section)

    return unless enrollment && enrollment.blocked?

    flash[:warning] = 'There is a short delay when enrolling. You cannot access the ' \
                      'activities until it is resolved. Please try again after a few minutes. ' \
                      'If you continue to see this message, ' \
                      "#{'ask your instructor to help ' if current_section.course&.school&.k12?}" \
                      "#{submit_support_request_link}"
    redirect_to_student_dashboard
  end
  private :prevent_access_when_enrollment_locked

  private def redirect_to_student_dashboard
    path_args = {
      course_id: current_section.course_id,
      section_id: current_section.id
    }
    if supersite_junior?
      redirect_to jr_course_section_path(path_args)
    else
      redirect_to course_section_path(path_args)
    end
  end

  def set_activity_by_id
    # .unscoped is needed in order to display a preview of an instance of the
    # QuestionBank subclass of Activity, which would normally get excluded
    # via default_scope on Activity class.
    @activity = Activity.unscoped.find(params[:id]).extend(ActivityViewDecorator)
    # The set_current_program method needs to work a little differently if
    # the current activity is a question bank, as well as some view logic
    # in the return_to partial. Rather than trying to reload and re-assign
    # the @activity instance from the QuestionBank class (which is a
    # sub-class of Activity), it's easier to just assign an extra variable
    # to an instance of QuestionBank. The peformance hit from this should be
    # minimal, as question banks can only be viewed by TechProd.
    @question_bank = QuestionBank.find(params[:id]) if @activity.question_bank?
    @activity.question_bank_revision_id = params[:revision_id] if params[:revision_id]
  end
  private :set_activity_by_id

  def assign_activity_presenter
    # user_for_presenter could be current_user (activities controller) or
    # another user (e.g instructor/activities controller) because we need to
    # display the activity with student submission when the user is an instructor
    @activity_presenter ||= StudentActivityPresenter.new(@activity, user_for_presenter, current_section)
  end
  private :assign_activity_presenter

  def set_activity_by_cms_activity_id
    # There are some weird cases when the program_id param is removed from the request and
    # is replaced by a 'busted' param with a different (maybe random?) number.
    # That's why it's necessary to try with current_program.
    program_id = params[:program_id] || (current_program && current_program.id)

    @activity = Activity.find_by_cms_activity_id_in_program(params[:id], program_id)

    if @activity
      @activity.extend(ActivityViewDecorator)
    else
      error_message = "No activity found with cms_activity_id = #{params[:id]} " \
                      "and program_id = #{program_id.nil? ? 'nil' : program_id}"

      raise ::ActionController::RoutingError, error_message
    end
  end
  private :set_activity_by_cms_activity_id

  def set_current_program
    # QuestionBank is a subclass of Activity, but has no lesson or strand
    # or concept. However, @activity will be assigned to an instance of
    # Activity, even if the record is actually a QuestionBank, and the
    # call to .program will try and use the definition in the parent class
    # which will fail because of the nil lesson.
    # Having a separate @question_bank instance that is correctly cast as
    # a QuestionBank class ensures the .program call uses the overridden
    # definition from the subclass that bypasses the lesson.
    @current_program = @question_bank&.program || @activity.program
  end
  private :set_current_program

  private def ensure_correct_family
    return unless current_program.spr?

    redirect_to spr_section_activity_path(id: params[:id], section_id: params[:section_id])
  end

  def process_show_activity(presenter)
    if presenter.redirect_to_dashboard?
      if can_redirect_to_course_section(presenter)
        redirect_to_course_section(presenter)
      else
        set_ua_home_warning('Assessment content is only available for enrolled students.')
        redirect_to ua_home_path
      end
    else
      yield
    end
  end
  private :process_show_activity

  def can_redirect_to_course_section(presenter)
    # Handle scenario when a Student who is not enrolled into a Course/Section
    # tries to launch an Assessment from Google Classroom.
    if current_user.student? && activity.assessment?
      presenter.course.present? && presenter.section.present?
    else
      true
    end
  end
  private :can_redirect_to_course_section

  def redirect_to_course_section(presenter)
    flash[:notice] = presenter.flash_notice if presenter.flash_notice.present?
    path_args = { course_id: presenter.course.id, section_id: presenter.section.id }
    if supersite_junior?
      redirect_to jr_course_section_path(path_args)
    else
      redirect_to course_section_path(path_args)
    end
  end
  private :redirect_to_course_section

  def user_for_presenter
    current_user
  end
  private :user_for_presenter

  def assign_show_correct_answers
    @show_correct_answers = @activity_presenter.should_show_answers?
  end
  private :assign_show_correct_answers

  def assign_video_settings
    @video_settings = @activity_presenter.video_settings
  end
  private :assign_video_settings

  def ensure_correct_section
    correct_section = (
      current_user.current_section_in_program(@current_program, session) ||
      Section.section_zero
    )
    return if current_section == correct_section

    flash[:notice] = 'You have been redirected to the correct address for this activity.'

    # Query params joinchat, enable_video, pchatsession are required
    # when instructor initiates pchat call to student
    opts = params.permit(
      :id, :begin_work, :popup, :joinchat, :enable_video, :pchatsession, :program_id
    ).to_h.symbolize_keys.merge(section_id: correct_section)

    if params[:action] == 'popup'
      redirect_to popup_section_activity_path(opts)
    else
      redirect_to section_activity_path(opts)
    end
  end
  private :ensure_correct_section

  private def log_time_spent_error_cases
    TimeSpentErrorReporter.new(
      params[:start_time], time_now_in_seconds, request
    ).evaluate_and_log_error_cases
  end

  def activity
    @activity
  end

  def dismiss_notifications
    @activity_presenter.notifications.dismiss_all!
  end
  private :dismiss_notifications

  def ensure_can_access_activity
    if current_user.student? && @activity.listed?
      unless access_guardian.can_access_content?(@activity, @activity.lesson)
        if current_user.cartridge?
          flash[:error] = 'Sorry, but you do not have access to this item. %s'
          redirect_to cartridge_access_denied_path(@activity.id)
        else
          flash[:error] = 'Sorry, but you cannot access that activity.'
          redirect_to BestDefaultPath.best_default_path(
            current_user, current_program, current_section, session
          )
        end
      end
    end
  end
  private :ensure_can_access_activity

  def set_assignment_validator
    # We use this to show additional information to the instructor about whether or
    # not they can assign a particular activity.
    if current_user.instructor?
      @assignment_validator = AssignmentValidator.new(current_user, current_focus.course, nil)
    end
  end
  private :set_assignment_validator

  private def require_chat_enabled

    return if chat_enabled?
    set_chat_error_message(determine_chat_type)

    redirect_to BestDefaultPath.best_default_path(
      current_user, current_program, assigned_user_section, session
    )
  end

  private def set_chat_error_message(chat_type)
    if !current_user.instructor? && !assigned_user_section&.course
      flash[:error] = "You are not enrolled in a course, #{chat_type} is disabled."
    elsif assigned_user_section&.course&.school&.has_chat_support_disabled?
      flash[:error] = 'Your institution has disabled chat support.'
    else
      flash[:error] = "Your instructor has disabled #{chat_type} for this course"
    end
  end

  # Chat is enabled if:
  #   - the school has chat support enabled
  #   - current_user is an instructor
  #   - we are a student in a section, and the parent course has
  #     turned on partner chat
  private def chat_enabled?
    return false if assigned_user_section&.course&.school&.has_chat_support_disabled?

    current_user.instructor? || assigned_user_section&.course&.partner_chat_enabled?
  end

  private def ai_virtual_chat_enabled?
    return true if current_user.instructor?

    return true if ai_virtual_chat_activity? && assigned_user_section&.course&.ai_virtual_chat_level

    false
  end

  private def require_ai_virtual_chat_enabled
    unless ai_virtual_chat_enabled?
      classwork = Classwork.new(current_user, current_section_id)
      workset = classwork.current_workset(activity)
      next_act = workset&.next_activity(activity)

      if next_act && next_act != Workset::LAST_ACTIVITY
        set_chat_error_message('AI Chat')
        redirect_to section_activity_path(current_section_id, next_act.id)
      else
        set_chat_error_message('AI Chat')
        redirect_to BestDefaultPath.best_default_path(
          current_user, current_program, assigned_user_section, session
        )
      end
    end
  end

  private def determine_chat_type
    return 'Partner Chat' if partner_chat_activity?
    return 'Group Chat' if group_chat_activity?
    return 'AI Chat' if ai_virtual_chat_activity?

    'chat'
  end

  # Determines the appropriate section assigned to the user:
  #   - For 'permalink' action, students in the default section_zero
  #       are assigned their best active section within the program.
  #   - In all other cases, the current_section is returned.
  private def assigned_user_section
    return current_section unless action_name == 'permalink'

    return current_user.current_section_in_program(current_program) if
      current_section == Section.section_zero && current_user.student?

    current_section
  end

  private def chat_activity?
    partner_chat_activity? || group_chat_activity?
  end

  private def ai_virtual_chat_activity?
    @activity.ai_virtual_chat?
  end

  private def group_chat_activity?
    @activity.group_chat?
  end

  private def partner_chat_activity?
    @activity.partner_chat?
  end

  def assign_course_policy
    @course_policy = CourseLibraryEditPolicy.new(current_user, current_focus) if current_user.instructor?
  end
  private :assign_course_policy

  # The parameter keys for activity submissions can't be predicted in advance.
  private def activity_params_hash
    return @activity_params_hash if defined? @activity_params_hash

    @activity_params_hash = params.permit!.to_h.with_indifferent_access
    if @activity.group_chat? && @activity_params_hash['partner_id'].present? &&
       @activity_params_hash['partner_section_id'].present?
      @activity_params_hash['partner_id'] = JSON.parse(@activity_params_hash['partner_id'])
      @activity_params_hash['partner_section_id'] = JSON.parse(@activity_params_hash['partner_section_id'])
    end
    @activity_params_hash
  end

  private def randomize_assessment?
    %w[exam multi_type].include?(@activity&.activity_type) && @activity_presenter&.randomize_assessment?
  end

  private def set_show_not_enrolled_warning
    @show_not_enrolled_warning = current_section.zero? && current_user.student?
  end

  private def video_chat_recording?
    @activity_presenter.partner_chat? ||
    @activity_presenter.solo_video_recording_or_included_in_multipart_activity? ||
    @activity_presenter.group_chat?
  end

  private def load_custom_rubric
    # The first condition will be met by hybrid reading activities, or any
    # activity in the future that adds support for inline rubrics. The second
    # is to ignore any such activities that support inline rubrics but don't
    # currently have one.
    return unless @activity.content_object.respond_to?(:inline_rubric)

    unless @activity.content_object.inline_rubric.nil?
      if current_focus.nil?
        custom_rubric_loader = CustomRubricLoader.new(@activity, current_user, current_section)
      else
        custom_rubric_loader = CustomRubricLoader.new(@activity, current_user, nil, current_focus)
      end
      custom_rubric_loader.load_xml_from_custom_rubric
    end
  end

  private def submit_support_request_link
    view_context.link_to(
      'submit a support request',
      'https://support.vhlcentral.com/hc/en-us/requests/new',
      target: '_blank'
    )
  end
end
