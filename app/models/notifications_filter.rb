class NotificationsFilter

  def initialize(current_section, notification_list)
    @current_section = current_section
    @notification_list = notification_list
  end

  def notifications
    @notification_list.reject do |notification|
      # filter activity notifications if the assessment grades are not available
      grades_not_available_for(notification)
    end
  end

  def assessment_assignments
    @assignments ||= Assignment.assessments_for_section(@current_section).inject({}) do |hsh, assignment|
      hsh[assignment.assignable_id] = assignment
      hsh
    end
  end

  def grades_not_available_for(notification)
    # assessment_grade_available? is expensive for 'on_grading'
    # so we only want to check if there's an assignment for the notification
    # and the assignment is for an Activity
    # and this is not a reset work notification
    notification.activity_id.present? &&
      assessment_assignments[notification.activity_id].present? &&
      assessment_assignments[notification.activity_id].assignable_type == 'Activity' &&
      notification.type != 'ActivityResetWorkNotification' &&
      !assessment_assignments[notification.activity_id].assessment_grade_available?
  end
end
