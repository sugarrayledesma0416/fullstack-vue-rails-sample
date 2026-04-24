class DroppableStudentsPresenter
  def initialize(students, sections)
    @students = students
    @sections = sections
  end

  def droppable_students_info
    @droppable_students_info ||= droppable_enrollments.map { |enrollment|
                                 {
                                  user:    enrollment.user,
                                  course:  enrollment.course,
                                  section: enrollment.section,
                                  blocked: enrollment.blocked,
                                  json:    {user_id:    enrollment.user_id,
                                            section_id: enrollment.section_id,
                                            blocked:    enrollment.blocked}.to_json
                                 }
    }
  end

  def droppable_enrollments
    Enrollment
      .by_section_and_student(@sections, @students)
      .joins(:user)
      .order('users.last_name')
      .active_or_completed.includes(section: :course)
  end

  ENROLLMENT_BLOCKED_CALL = 'This enrollment may not be modified at ' \
                            'this time. Contact Technical Support' \
                            'for assistance.'.freeze

  def enrollment_blocked_text(list_idx)
    enrollment_blocked?(list_idx) ? ENROLLMENT_BLOCKED_CALL : ''
  end

  def checkbox_row_disabled(list_idx)
    enrollment_blocked?(list_idx) ? 'is-disabled' : ''
  end

  def enrollment_blocked?(list_idx)
    droppable_students_info[list_idx][:blocked]
  end
end
