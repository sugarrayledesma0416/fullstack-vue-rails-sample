class ScoreControlsViewManager
  include Instructor::GradingSetHelper
  include InstructorGradableQuestionCheckable
  include PendingTrueFalseEnhancedCheckable

  attr_accessor :question, :feedback_item, :results, :response_id, :params
  delegate :points_possible, :to => :question

  def initialize(question, feedback_item, results, response_id, params)
    self.question      = question
    self.feedback_item = feedback_item
    self.results       = results
    self.response_id   = response_id
    self.params        = params
  end

  def attempt_id(presenter, user_id)
    student = User.unscoped.find user_id if user_id

    feedback_item&.attempt_id ||
      presenter.feedback.attempt_for_student(student.presence || presenter.current_student).id
  end

  def score_field
    "score_for_#{response_id}"
  end

  def question_points
    if params[score_field].present?
      format_points_earned(params[score_field])
    else
      format_points_earned(current_points_earned)
    end
  end

  def rubric_criteria_score_by_title(title)
    return unless feedback_item && RubricCriteriaScore.find_by(attempt_id: feedback_item.attempt_id)

    criteria_score_json = JSON.parse(
      RubricCriteriaScore.find_by(
        attempt_id: feedback_item.attempt_id
      ).criteria_score_json.gsub('=>', ':')
    )

    criteria_score_json[title]
  end

  def rubric_criteria_scores
    return unless feedback_item && RubricCriteriaScore.find_by(attempt_id: feedback_item.attempt_id)
    RubricCriteriaScore.find_by(
        attempt_id: feedback_item.attempt_id
    ).scores.to_json
  end

  private def current_points_earned
    if question.is_a?(::Smartbook::Response)
      if question.instructor_gradable?
        points_from_feedback
      elsif results.blank?
        # If the student didn't answered the question, use the points from
        # the feedback item if present.
        points_from_feedback || 0.0
      else
        points_from_feedback || (results.score * question.points_possible).to_f
      end
    elsif instructor_gradable?
      points_from_feedback
    else
      points_from_feedback || results.points_earned(question.label).to_f
    end
  end

  private def points_from_feedback
    feedback_item && feedback_item.points_earned
  end

  # True either when question is a type that is always instructor-gradable, or
  # a true-false enhanced type, which is instructor-gradable only when false.
  private def instructor_gradable?
    instructor_gradable_type?(question) || pending_true_false_enhanced?(question)
  end

  def recording_path
    @results.find { |item| item[:label] == @question.label }[:response].recording_path
  end
end
