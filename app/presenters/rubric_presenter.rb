class RubricPresenter
  attr_accessor :rubric, :header_columns
  attr_writer :attempt

  delegate :criterias_with_ordered_performances, to: :rubric

  def initialize(rubric, attempt = nil)
    @rubric = rubric
    @header_columns = rubric.header_row.header_columns
    @attempt = attempt
  end

  def scores
    criteria_scores&.scores
  end

  def show_scores?
    criteria_scores.present?
  end

  def format_points_earned_vs_possible
    "#{student_name} #{criteria_scores.sum}/#{max_points}"
  end

  private def criteria_scores
    return unless @attempt&.complete?

    @criteria_scores ||= RubricCriteriaScore.find_by(attempt_id: @attempt.id)
  end

  private def student_name
    User.find(@attempt.user_id).full_name if @attempt
  end

  private def max_points
    rubric.points_possible
  end
end
