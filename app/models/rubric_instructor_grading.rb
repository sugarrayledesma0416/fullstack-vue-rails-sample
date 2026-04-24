class RubricInstructorGrading
  attr_accessor :activity_id, :section_id, :student_id

  def initialize(activity_id, section_id, student_id)
    self.activity_id = activity_id
    self.section_id = section_id
    self.student_id = student_id
  end

  def grade_pending?
    return true unless score_action

    score_action.summation['pending'].to_s.downcase == 'true'
  end

  def rubric_graded?
    return false unless score_action

    score_action.summation['rubric_graded'].to_s.downcase == 'true'
  end

  private def score_action
    @score_action ||= GradebookEngine::GradebookAPI.find_score(
      activity_id: activity_id,
      section_id: section_id,
      user_id: student_id
    )
  end
end
