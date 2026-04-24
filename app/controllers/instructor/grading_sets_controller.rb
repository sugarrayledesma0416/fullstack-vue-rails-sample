class Instructor::GradingSetsController < RequireInstructorController
  helper MaestroActivityEngine::ActivitiesHelper
  include Uploadable::Controller
  include Redirectable
  include Instructor::SmartbookAudioPlayback
  include CartridgeViewable
  include GradePassback

  before_action :assign_recording_server_url, only: %i[edit update]
  before_action :assign_allowed_file_types, only: :edit

  include HasHelp
  before_action :contextual_help_url, only: %i[edit edit_confirm update]
  before_action :assign_grading_set_and_check_permissions,
                only: %i[edit edit_confirm update]

  include ActionView::Helpers::TextHelper #needed to for pluralize method

  NO_SUBMISSIONS_TO_REVIEW_MSG = 'There are currently no submissions to review.'.freeze

  def create
    student_ids = params[:selected_students]
    grading_set = GradingSet.create_or_update(current_user.id, params, student_ids)
    redirect_to edit_instructor_grading_set_path(params[:program_id], grading_set,
                                                 task_type: params[:task_type])
  end

  def edit
    @angular_controller = 'instructorActivityRequestsCtrl'
    @show_correct_answers = true
    assign_grading_style
    assign_presenter_and_view_managers
    @page_title = @presenter.page_title
    @activity = @presenter&.activity

    if @presenter.has_nothing_to_grade?
      flash[:error] = no_submissions_to_review_error
      redirect_to instructor_grading_styles_path(program_id: current_program,
                                                 activity_id: @presenter.activity,
                                                 task_type: params[:task_type],
                                                 return_to: params[:return_to])
    elsif student_by_student? && (@presenter.current_student.blank? || @presenter.student_attempts[@presenter.current_student.id.to_s].blank?)
      flash[:error] = 'An error has occured. Please click on "Start Grading".'
      redirect_to instructor_grading_styles_path(program_id: current_program,
                                                 activity_id: @presenter.activity,
                                                 task_type: params[:task_type])
    elsif @presenter.students_submitted_multiple_versions? && question_by_question?
      flash[:warning] = 'Different versions of this activity exist. You may only grade student by'\
                        ' student.'
      redirect_to instructor_grading_styles_path(program_id: current_program,
                                                 activity_id: @presenter.activity,
                                                 task_type: params[:task_type])
    else
      assign_lossless_auth_token if @presenter.assign_lossless_auth_token?
      render
    end
  end

  private def no_submissions_to_review_error
    if params[:return_to]
      "#{NO_SUBMISSIONS_TO_REVIEW_MSG} <a href=\"#{vhl_return_to_sanitizer(
        params[:return_to]
      )}\">Return to the Gradebook</a>.".html_safe
    else
      NO_SUBMISSIONS_TO_REVIEW_MSG
    end
  end

  def edit_confirm
    assign_grading_style
    assign_presenter_and_view_managers
    @activity = @presenter&.activity

    render :edit_confirm, :layout => false
  end

  def update
    assign_grading_style
    @grading_set.update_state(params)
    assign_presenter_and_view_managers
    @activity_id = @grading_set.activity_id
    @activity = @presenter&.activity

    if @activity.ai_virtual_chat? && params[:ai_chat_feedback].present?
      AI::ChatFeedbackProcessor.new(
        params_json: params[:ai_chat_feedback],
        program: current_program,
        activity: @activity,
        instructor: current_user
      ).process!
    end

    grading_params = params.merge(cartridge_params: cartridge_grade_params)

    submission = if question_by_question?
                   InstructorGradingSubmission.new(
                     current_user,
                     @presenter.activity,
                     @presenter.students_to_submit,
                     [@presenter.current_question],
                     @presenter.feedback,
                     @presenter.student_attempts,
                     grading_params
                   )
                 else
                   InstructorGradingSubmission.new(
                     current_user,
                     @presenter.activity,
                     ([@presenter.current_student] + @presenter.teammates).compact,
                     @presenter.questions_to_grade,
                     @presenter.feedback,
                     @presenter.student_attempts,
                     grading_params
                   )
                 end


    submission_successful = submission.process_submission

    unless submission_successful
      @presenter.invalid_scores = submission.invalid_scores
    end

    # Show CE warnings only at the end of grading (only when we have actual CE issues)
    if (@presenter.last_item? || @presenter.done?) && submission.concurrent_enrollment_failures?
      if submission.all_students_failed_ce?
        flash[:error] = submission.concurrent_enrollment_warning_message
      else
        flash[:warning] = submission.concurrent_enrollment_warning_message
        flash[:notice] = "#{@presenter.activity.title} has been successfully graded."
      end
    elsif submission_successful && (@presenter.last_item? || @presenter.done?)
      flash[:notice] = "#{@presenter.activity.title} has been successfully graded."
    end

    if submission_successful && submission.invalid_scores.empty?
      if @presenter.last_item?
        if @grading_style == Setting::GradingTasks::GradingStyle::SPOTCHECK
          StudentSpotcheckCount.create_or_update(
            @presenter.students_to_grade.map(&:id), current_section.id
          )
          @show_finish_spotchecking = true
          @grading_status = @grading_set.grading_status_of_students(current_focus.sections)
          render :edit
        else
          if current_user.cartridge?
            redirect_to cartridge_section_activity_path(current_section, @activity_id)
          else
            redirect_to return_from_grading_path
          end
        end
      else
        if @presenter.done?
          if current_user.cartridge?
            redirect_to cartridge_section_activity_path(current_section, @activity_id)
          else
            redirect_to return_from_grading_path
          end
        else
          redirect_to edit_instructor_grading_set_path current_program, @grading_set, @presenter.next_element.merge({ task_type: params[:task_type] })
        end
      end
    else
      assign_lossless_auth_token if @presenter.assign_lossless_auth_token?
      render :edit
    end
  end

  def instructor_grading_tasks_presenter
    @instructor_grading_tasks_presenter ||= InstructorGradingTasksPresenter.new(
      current_task: params[:task_type],
      section_ids: current_focus.sections.map(&:id),
      student_ids: current_focus.students.map(&:id)
    )
  end

  def assign_presenter_and_view_managers
    show_auto_graded_questions = current_user.setting(Setting::GradingTasks::ShowAutoGradedQuestions)
    if question_by_question?
      @presenter = QuestionByQuestionPresenter.new(current_user,
                                                   @grading_set,
                                                   @program,
                                                   @sections,
                                                   params,
                                                   show_auto_graded_questions).prepare
      @view_manager = QuestionByQuestionViewManager.new(@presenter)
    else
      @presenter = StudentByStudentPresenter.new(current_user,
                                                 @grading_set,
                                                 @program,
                                                 @sections,
                                                 instructor_grading_tasks_presenter,
                                                 params,
                                                 show_auto_graded_questions).prepare
      @view_manager = StudentByStudentViewManager.new(@presenter)
      if @presenter.has_rubric?
        @user_scores_for_rubric_grading = UserScoresForGrading.new(
          @presenter,
          params,
          recording_configuration_instance
        )
        @user_scores_json = @user_scores_for_rubric_grading.score_list.to_json
        @comment_boxes = @user_scores_for_rubric_grading.comment_boxes
      end
    end
  end
  private :assign_presenter_and_view_managers

  def assign_grading_style
    @grading_style = current_user.setting(Setting::GradingTasks::GradingStyle)
    @spotcheck_style = current_user.setting(Setting::GradingTasks::SpotcheckStyle)
  end
  private :assign_grading_style


  def assign_grading_set_and_check_permissions
    @grading_set = GradingSet.find(params[:id])
    redirect_inappropriate_access unless @grading_set.owned_by?(current_user)
  end
  private :assign_grading_set_and_check_permissions

  def redirect_inappropriate_access
    flash[:error] = "You are trying to access a page for which you don't have appropriate permissions."
    return redirect_to BestDefaultPath.best_default_path(
      current_user, current_program, current_section, session
    )
  end
  private :redirect_inappropriate_access

  def assign_recording_server_url
    @recording_server_url = recording_configuration_instance.server_host
  end
  private :assign_recording_server_url

  def question_by_question?
    @grading_style == Setting::GradingTasks::GradingStyle::BY_QUESTION
  end
  private :question_by_question?

  def student_by_student?
    @grading_style == Setting::GradingTasks::GradingStyle::BY_STUDENT
  end
  private :student_by_student?
end
