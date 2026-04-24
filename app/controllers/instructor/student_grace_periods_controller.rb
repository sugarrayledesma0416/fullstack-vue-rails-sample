class Instructor::StudentGracePeriodsController < RequireInstructorController

  include HasHelp
  before_action :contextual_help_url
  skip_before_action :assign_course_sections_and_students_from_focus

  def index
    @presenter = InstructorStudentGracePeriodsPresenter.new(current_user, current_focus, params)
    @return_to = params[:return_to] || instructor_dashboard_path(current_program)
    @page_title = 'Manage Grace Periods'
    @page_header = 'Grant grace period access'
    @hide_header = true
    @no_app_shell = true
    render :layout => 'application_v3'
  end

  def create
    @presenter = InstructorStudentGracePeriodsPresenter.new(current_user, current_focus, params)
    @return_to = params[:return_to]
    @page_title = 'Manage Grace Periods'
    @page_header = 'Grant grace period access'
    @hide_header = true
    @no_app_shell = true
    if has_required_params?(params)
      process_grace_periods(params)

      if @errors.present?
        @errors.flatten!
        flash.now[:error] = @errors.join("\n")
      end

      if @students_granted.present?
        redirect_to @return_to, { :notice => "The following have been granted grace periods: " + @students_granted.map(&:full_name).join(", ") }
      else
        render :index, :layout => 'application_v3'
      end
    else
      flash.now[:error] = @errors.join("\n")
      render :index, :layout => 'application_v3'
    end
  end

  def process_grace_periods(opts)
    course = Course.find(opts['course_id'])
    student_ids = opts['selected_student_ids']
    if enough_grace_periods?(student_ids, course.school_id)
      @students_granted = Array.new
      student_ids.each do |student_id|
        results = Maestro::User.grant_student_grace_period_access(User.find_guid(student_id), course.guid)
        if results['errors'].present?
          @errors << results['errors']
        else
          student = current_focus.students.detect { |student| student.id == student_id.to_i }
          @students_granted << student
        end
      end
    end
  end
  private :process_grace_periods

  def enough_grace_periods?(student_ids, school_id)
    allocation = GracePeriodAllocation.new(school_id)
    unless allocation.remaining > student_ids.size
      @errors << 'Your school does not have enough grace periods available for the selected students.'
    end
    @errors.empty?
  end

  def has_required_params?(params)
    @errors = Array.new
    unless params['selected_student_ids'].present?
      @errors << 'You must select at least one student.'
    end
    @errors.empty?
  end
  private :has_required_params?
end
