module Gradebook
  class InstructorGrading
    attr_accessor :score_action, :new_points_earned, :reset_partial_pending

    def initialize(score_action, new_points_earned, reset_partial_pending: false)
      @new_points_earned = new_points_earned
      @score_action = score_action
      @reset_partial_pending = reset_partial_pending
    end

    def process
      GradebookEngine::GradebookAPI.grade(
        score_action.user_id,
        score_action.section_id,
        score_action.activity_id,
        score_action.school_id,
        {
          points_earned: new_points_earned.to_f,
          rubric_graded: score_action.summation['rubric_graded']
        }.tap do |memo|
          memo[:partial_pending] = false if reset_partial_pending
        end
      )
    end
  end
end
