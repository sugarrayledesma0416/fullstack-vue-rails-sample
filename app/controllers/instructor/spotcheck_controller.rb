class Instructor::SpotcheckController < RequireInstructorController
  include HasHelp
  include Redirectable
  include CartridgeViewable
  include GradePassback

  before_action :contextual_help_url
  before_action :set_cache_buster

  def students_index
    @activity_id = params[:activity_id]
    @activity = Activity.find(params[:activity_id])
    @task_type = params[:task_type]

    @spotcheck_style = current_user.setting(Setting::GradingTasks::SpotcheckStyle)

    students = current_focus.students

    students.each do |student|
      student.my_current_section = current_section
    end

    @spotcheck_list = SpotcheckList.new(
      activity_id: @activity_id,
      section_ids: @sections.map(&:id),
      students:,
      unassigned: @task_type == 'unassigned_activities_section'
    )

    @num_random_students_count = current_user.setting(Setting::GradingTasks::SpotcheckSelectedRandomStudentsCount)
    @num_outliers_count = current_user.setting(Setting::GradingTasks::SpotcheckSelectedOutliersCount)
    @page_title = 'Grading - Spotcheck'
  end

  def update
    @grading_set = GradingSet.find(params[:grading_set_id])
    @activity = Activity.find(@grading_set.activity_id)
    if params[:grant_grade] == '100'
      @grading_set.grade_all_full_credit(
        sections: @sections,
        cartridge_params: cartridge_grade_params,
        students: @students
      )
    end
    unless params[:comment].blank?
      @grading_set.comment_all(
        comment: params[:comment],
        sections: @sections,
        cartridge_params: cartridge_grade_params,
        students: @students
      )
    end

    if @grading_set.errors.empty?
      flash[:notice] = "Spotchecking for the activity #{@activity.title} was completed successfully." if params[:grant_grade] == '100'
      flash[:notice] = "General comments were applied to all students for the activity #{@activity.title}." if (params[:grant_grade] != '100' && !params[:comment].blank?)
      flash[:notice] = "No changes were made for the activity #{@activity.title}." if (params[:grant_grade] != '100' && params[:comment].blank?)
    else
      flash[:error] = "Spotchecking for activity #{@activity.title} failed."
    end

    respond_to do |format|
      format.html do
        redirect_to return_from_grading_path
      end
    end
  end

  def update_style
    current_user.set(Setting::GradingTasks::SpotcheckStyle, params[:spotcheck_style])
    head :ok
  end

  def update_selected_students_count
    current_user.set(Setting::GradingTasks::SpotcheckSelectedRandomStudentsCount, params[:select_num_of_random_students]) if params[:select_num_of_random_students]
    current_user.set(Setting::GradingTasks::SpotcheckSelectedOutliersCount, params[:select_num_of_outliers]) if params[:select_num_of_outliers]
    head :ok
  end
end
