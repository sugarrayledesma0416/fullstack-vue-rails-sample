class StudentRoster
  # associates students with the section they are enrolled in
  # and provides efficient access to student section and enrollments
  # without additional queries
  #
  # @param students [Array] of student objects, not ids
  # @params sections [Array] of section objects, not ids
  def initialize(students, sections)
    @students = students.inject({}) { |h, student| h[student.id] = student; h }
    @sections = sections.inject({}) { |h, section| h[section.id] = section; h }
  end

  def section_for_student(student)
    @section_for_student ||= enrollments.inject({}) do |memo, enrollment|
      memo[enrollment.user_id] = @sections[enrollment.section_id]
      memo
    end
    @section_for_student[student.id]
  end

  def enrollment_for_student(student)
    @enrollment_for_student ||= enrollments.inject({}) do |memo, enrollment|
      memo[enrollment.user_id] = enrollment
      memo
    end
    @enrollment_for_student[student.id]
  end

  def students_in_section(section)
    @students_in_section ||= enrollments.inject({}) do |memo, enrollment|
      memo[enrollment.section_id] ||= []
      memo[enrollment.section_id] << @students[enrollment.user_id]
      memo
    end
    @students_in_section[section.id]
  end

  def enrollments
    @enrollments ||= Enrollment.find_all_active_or_completed_by_users_and_sections(@students.values, @sections.values)
  end
  private :enrollments
end