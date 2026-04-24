class MaxAttemptPolicy
  def initialize(activity, assignment)
    @activity = activity
    @assignment = assignment
  end

  def unsubmittable?
    max_attempts_for_activity_content == 0
  end

  def assessment_override
    @assignment.assigned_assessment_detail.number_of_attempts
  end
  private :assessment_override

  def max_attempts_for_activity_content
    @activity.max_attempts ? @activity.max_attempts : -1
  end
  private :max_attempts_for_activity_content

  def max_attempts_for_category
    @assignment.max_attempts
  end
  private :max_attempts_for_category

  def max_attempts
    # this method returns the maximum of attempts the student has on the
    # activity related to this attempt.
    # cases
    # 1) activity is assigned into a category with a category-level max attempts setting,
    #    and has an override that can be different, and also different from the activity
    #    setting.
    # 2) if the max attempts set for the activity is unlimited, we use the
    #    maximum attempts allowed on the assignment category. (If the activity
    #    is not assigned max_attempts_for_category returns unlimited).
    # 3) if the max attempts set for the activity is set and the maximum
    #    attempts allowed on the assignment category is unlimited, we use
    #    the activity one. (This works for assessments since we don't want to
    #    allow more than one attempt, even if the instructor tries to ovewrite the value).
    # 4) if both the activity maximum attempts and assignment maximum attempts have
    #    been set we return the lowest value of the two. (this applies for the same reason as [3]
    #    but also to let the instructor overwrite the max number of attempts on non-assessment
    #    activities).
    if @assignment
      if assessment_override_exists? # (1)
        assessment_override
      elsif activity_content_unlimited? # (2)
        max_attempts_for_category
      elsif category_unlimited?
        max_attempts_for_activity_content # (3)
      else # (4)
        most_restrictive_between_activity_and_category
      end
    else
      max_attempts_for_activity_content
    end
  end

  def most_restrictive_between_activity_and_category
    [max_attempts_for_activity_content, max_attempts_for_category].min
  end
  private :most_restrictive_between_activity_and_category

  def assessment_override_exists?
    @activity.assessment? && @assignment.assigned_assessment_detail
  end
  private :assessment_override_exists?

  def activity_content_unlimited?
    max_attempts_for_activity_content == -1
  end
  private :activity_content_unlimited?

  def category_unlimited?
    max_attempts_for_category == -1
  end
  private :category_unlimited?

end
