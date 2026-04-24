class GradingStudentListBase
  include IndividualAssignmentQueryable

  attr_accessor :activity_id, :section_ids, :students
  attr_writer :unassigned_grading_set

  def initialize(activity_id:, section_ids:, students:, unassigned:)
    self.activity_id = activity_id
    self.section_ids = section_ids
    self.students = students
    self.unassigned_grading_set = unassigned
  end

  private def filtered_students
    @filtered_students ||= students.select do |student|
      is_assigned = assigned_student_ids.include?(student.id)

      # For an unnassigned work grading set, only return students for
      # whom the activity is not assigned. For other worksets, only
      # return students for whome the work is assigned.
      if unassigned_grading_set?
        !is_assigned
      else
        is_assigned
      end
    end
  end

  private def assigned_student_ids
    @assigned_student_ids ||= individual_assignment_scope.map do |entry|
      entry.user_id if !entry.individually_assignable? || entry.individually_assigned?
    end.uniq.compact
  end

  # individual_assignment_grading_set_scope is defined in
  # module IndividualAssignmentQueryable
  private def individual_assignment_scope
    individual_assignment_grading_set_scope([activity_id], section_ids)
  end

  private def unassigned_grading_set?
    @unassigned_grading_set
  end
end
