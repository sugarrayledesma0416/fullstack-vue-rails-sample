class StudentAssignmentMap
  attr_reader :students

  def initialize(section, students, assignments)
    @assignments = assignments || []
    @section = section
    @students = students
  end

  def assignment_count
    @assignments.size
  end

  def student_assignment_counts
    @scores_by_student_id ||= scores_for_assignments.each_with_object(
      Hash.new { |k, v| k[v] = 0 }
    ) do |score, memo|
      memo[score.user_id] += 1
    end
  end

  private def scores_for_assignments
    GradebookEngine::GradebookAPI.find_submitted(
      activity_id: @assignments.map(&:assignable_id),
      section_id: @section.id,
      user_id: students.map(&:id)
    )
  end
end
