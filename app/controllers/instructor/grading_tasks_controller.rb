class Instructor::GradingTasksController < RequireInstructorController
  include HasHelp
  include CartridgeViewable
  before_action :contextual_help_url
  before_action :assign_menu_coords

  def assignments_index
    @grading_style = current_user.setting(Setting::GradingTasks::GradingStyle)
    @task_type = params[:task_type] || GradingTask::NEEDS_GRADING
    @task_list = build_task_list(@task_type)
    @page_title = 'Grading'
    render
  end

  def activities_index
    @task_type = params[:task_type]
    @task_list = build_task_list(@task_type)
    render '_activities_index', layout: false
  end


  def start_ai_feedback
    grading_set = find_or_create_grading_set

    attempts = Attempt.where(activity_id: params[:activity_id].to_i, section_id: params[:section_id].to_i)
    grading_jobs = AI::GradingSuggestionJob.where(
      attempt_id: attempts.pluck(:id)
    )

    failed_jobs = grading_jobs.where(status: 'failed')

    failed_jobs.update_all(status: 'processing')

    AI::GradingSuggestionWorker.perform_async(attempts.pluck(:id))
    render json: { grading_set_id: grading_set.id, status: 'processing' }
  end

  def grading_status
    status = AI::SuggestionBatchStatus.new(params[:activity_id], params[:section_id]).status
    render json: { status: }
  end

  def grade_activity
    grading_set = find_or_create_grading_set
    grading_set.update(show_comments: true) if grading_set.activity.chat_or_recording?

    redirect_after_grading(grading_set)
  end

  def find_or_create_grading_set_id
    begin
      grading_set = find_or_create_grading_set
      render json: { grading_set_id: grading_set.id }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private def assign_menu_coords
    @menu_location = 'grades'
  end

  private def build_task_list(task_type)
    ::InstructorGradingTasksPresenter.new(
      current_task: task_type,
      section_ids: @sections.map(&:id),
      student_ids: current_focus.students.map(&:id)
    )
  end

  private def find_or_create_grading_set
    activity = Activity.find(params[:activity_id].to_i)
    student_ids = fetch_student_ids(activity.id)

    begin
      GradingSet.create_or_update(
        current_user.id,
        { activity_id: activity.id, program_id: params[:program_id].to_i },
        student_ids
      )
    rescue => e
      raise e
    end
  end

  private def fetch_student_ids(activity_id)
    GradingSetStudentList.new(
      activity_id:,
      section_ids: @sections.map(&:id),
      unassigned: params[:task_type] == 'unassigned_activities_section',
      students: current_focus.students
    ).user_ids
  end

  private def redirect_after_grading(grading_set)
    if current_user.setting(Setting::GradingTasks::GradingStyle) == Setting::GradingTasks::GradingStyle::SPOTCHECK
      redirect_to instructor_spotcheck_activity_index_path(
        params[:program_id],
        params[:activity_id],
        task_type: params[:task_type]
      )
    else
      redirect_to edit_instructor_grading_set_path(
        params[:program_id],
        grading_set,
        student_id: grading_set.first_gradable_student(@sections),
        task_type: params[:task_type],
        return_to: params[:return_to]
      )
    end
  end
end
