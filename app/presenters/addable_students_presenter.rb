class AddableStudentsPresenter
  attr_reader :program

  def initialize(schools, program, opts)
    @schools = schools # instructor's schools association
    @program = program
    @opts = opts
    Rails.logger.debug("OPTS: #{opts}")
  end

  def students
    # Added pluck on @schools to fix error:
    # NoMethodError:
    #        undefined method `reverse' for nil:NilClass
    return @students if defined? @students
      prospective_students = Student.not_fake
                         .joins(:school_users)
                         .where(school_users: { school_id: @schools.pluck(:id) })
                         .where('email in(:search_string) ' \
                                'OR username in (:search_string) ' \
                                'OR first_name in(:search_string) ' \
                                'OR last_name in(:search_string)',
                                search_string: search_string)
                         .distinct
    @students = prospective_students.reject(&:one_roster?)
  end

  def active_enrollments_for_student(student)
    @enrollments ||= {}
    @enrollments[student.id] ||= student.active_enrollments(:section)
  end

  def blocked_enrollment_msg
    "This enrollment may not be modified at this time. Contact Technical Support for assistance."
  end

  def enrollments_for_program_blocked?(student)
    active_enrollments_for_student(student).select do |enrollment|
      enrollment.program.id == @program.id
    end.map(&:blocked?).any?
  end

  def program_title_for_section(section)
    section.program.title
  end

  def school_name_for_section(section)
    section.school.name
  end

  def course_name_for_section(section)
    section.course.name
  end

  def instructor_name_for_section(section)
    section.instructor.full_name
  end

  def selected_section_id
    @opts[:section_id]
  end

  def return_to
    @opts[:return_to]
  end

  def search_string
    @opts[:search_str].match(" ") ? @opts[:search_str].split(" ") : @opts[:search_str]
  end
  private :search_string
end
