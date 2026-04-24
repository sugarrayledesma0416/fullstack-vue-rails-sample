module InstructorAssignableActivity
  delegate :assignable?, :any_assignable?, :unassignable_reason, to: :assignment_validator

  def assignment_validator
    return @assignment_validator if @assignment_validator

    @assignment_validator = AssignmentValidator.new(current_user, course, activities)
    @assignment_validator.validate
    @assignment_validator
  end

  def activity_row_class(activity)
    if assignable?(activity)
      ''
    else
      'unassignable_activity'
    end
  end
end
