module Smartbook
  class ScoreCalculator
    attr_accessor :attempt

    delegate :activity, :feedback_item, :smartbook_responses, to: :attempt

    def initialize(attempt)
      @attempt = attempt
    end

    def points_earned
      total_points_earned = auto_graded_points_earned + \
                            instructor_graded_points_earned
      total_points_possible = auto_graded_points_possible + \
                              instructor_graded_points_possible

      # We can have a total points possible of zero if the activity only
      # contains instructor-graded questions and none has been graded.
      if total_points_possible.zero?
        0.0
      else
        ((total_points_earned.to_f / total_points_possible) * activity.points_possible).round(2)
      end
    end

    # Returns the points earned with all the submitted auto-graded questions
    # The points earned come from either the feedback item or the question response.
    private def auto_graded_points_earned
      smartbook_responses.latest_auto_graded_responses.sum do |response|
        points_earned_from_feedback_item(response) || response.points_earned
      end
    end

    # Return the posible points for all the auto-graded questions
    # Non submitted auto-graded questions are worth 0 points so the possible
    # Points are always equals to the activity auto_graded_points_possible.
    private def auto_graded_points_possible
      activity.content_object.auto_graded_points_possible
    end

    # Returns the points earned with all graded instructor-graded questions
    private def instructor_graded_points_earned
      smartbook_responses.latest_instructor_graded_responses.sum do |response|
        # Use either the points earned from the feedback item or 0 for non-graded questions.
        points_earned_from_feedback_item(response) || 0
      end
    end

    private def points_earned_from_feedback_item(response)
      fb_item = feedback_item(response.label)
      if fb_item&.points_earned.present? && fb_item.updated_at >= response.submission_time
        # Use the feedback item when it has points earned and is more recent
        # than the latest submission
        fb_item.points_earned
      end
    end

    # Returns the possible points for all the instructor-graded questions.
    # We don't consider ungraded instructor-graded questions.
    private def instructor_graded_points_possible
      # We calculate the possible points of all the submitted but not yet
      # graded instructor-questions.
      need_grading_points_possible = smartbook_responses.latest_instructor_graded_responses.sum do |response|
        fb_item = feedback_item(response.label)
        if fb_item&.points_earned.present? && fb_item.updated_at >= response.submission_time
          0
        else
          response.points_possible
        end
      end
      activity.content_object.instructor_graded_points_possible - need_grading_points_possible
    end
  end
end
