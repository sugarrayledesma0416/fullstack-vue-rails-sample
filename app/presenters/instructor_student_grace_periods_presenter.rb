class InstructorStudentGracePeriodsPresenter
  attr_accessor :instructor, :program, :focus

  def initialize(instructor, current_focus, opts = {})
    self.instructor = instructor
    self.program = Program.find(opts[:program_id])
    self.focus = current_focus
  end

  def students_with_access_problems
    unless @students_with_access_problems
      @students_with_access_problems ||= Array.new
      if grace_periods.allowed?
        @students_with_access_problems = GradebookStudent.decorate(
          Student.where(id: filtered_students_with_access_problems).order(:last_name, :first_name).to_a,
          program,
          focus.sections
        )
      end
    end
    @students_with_access_problems
  end

  def students_with_grace_period
    unless @students_with_grace_period
      student_ids = problematic_students - filtered_students_with_access_problems
      @students_with_grace_period = GradebookStudent.decorate(
        Student.where(id: student_ids).order(:last_name, :first_name).to_a,
        program,
        focus.sections
      )
    end
    @students_with_grace_period
  end

  def filtered_students_with_access_problems
    problematic_students.inject([]) do |filter_students, student_id|
      filter_students << student_id unless has_grace_period_license?(student_id)
      filter_students
    end
  end

  def grace_periods
    @grace_period_allocation ||= GracePeriodAllocation.new(school.id)
  end

  def course
    focus.course
  end

  def school
    course.school
  end

  def has_grace_period_license?(student_id)
    @licenses ||= Hash.new
    unless @licenses[student_id.to_s]
      @licenses[student_id.to_s] = licenses_for_user(student_id)
    end
    @licenses[student_id.to_s].any? { |ul| ul.grace_period? }
  end

  def licenses_for_user(student_id)
    student_guid = User.find_guid(student_id)
    Maestro::UserLicense.all_for_user_and_program(student_guid, program.id)
  end

  def grace_period_days_remaning(student_id)
    return unless has_grace_period_license?(student_id)

    grace_period_user_license = @licenses[student_id.to_s].detect(&:grace_period?)
    [(grace_period_user_license.expiration_date - Time.zone.today).to_i, 0].max
  end

  # Returns the header for the column showing student sections
  #
  # The column header is generated based on the number of sections in focus.
  # If the course is in focus and multiple sections could be represented,
  # the header will be pluralized.
  #
  # @return [String] The header for the column showing student sections
  def section_column_header
    'Section'.pluralize(focus.sections.count)
  end

  private def problematic_students
    @problematic_students ||= focus.sections.flat_map do |section|
      section.current_active_enrollments.joins(:user).where(sufficient_access: false).map(&:user_id)
    end
  end
end
