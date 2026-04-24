class InstructorActivityPresenter
  include SharedActivityViewer

  attr_accessor :course

  def initialize(activity, user, section, course)
    super(activity, user, section)
    self.course = course
    self.notifications = []
  end

  def assignment
    return @assignment if defined?(@assignment)

    @assignment = section.assignment_by_activity(activity)
  end

  def unreviewed_notifications
    []
  end

  def activity_notes
    []
  end

  # current use is to determine whether or not there
  # are feedback items and a link to the feedback
  # panel should be shown in activity footer.
  # thus always false for an instructor
  def has_smartbook_attempt_with_feedback?
    false
  end

  # This method is also present in StudentActivityPresenter
  # Should we move it to SharedActivityViewer or to a separate file?
  def group_chat_selection_config
    assignment_config = @assignment&.group_chat_assignment_config
    if assignment_config
      { group_minimum: assignment_config.group_minimum - 1,
        group_maximum: assignment_config.group_maximum - 1 }
    else
      { group_minimum: activity.content_object.min_students_selection,
        group_maximum: activity.content_object.max_students_selection }
    end
  end

  def allows_expanded_notes?
    !(activity.partner_chat? ||
      activity.virtual_chat? ||
      activity.video_virtual_chat?)
  end
end
