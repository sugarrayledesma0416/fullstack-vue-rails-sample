class CourseLibraryEditPolicy
  attr_accessor :current_focus, :current_user

  def initialize(current_user, current_focus)
    self.current_focus = current_focus
    self.current_user = current_user
  end

  def can_edit?
    current_focus.focused? && editing_instructor?
  end

  def can_edit_activity?(activity)
    activity.is_owner?(current_user) && can_edit? && current_focus.course.open?
  end

  private def editing_instructor?
    CourseInstructorPolicy.new(current_focus.course, current_user).editing_instructor?
  end
end
