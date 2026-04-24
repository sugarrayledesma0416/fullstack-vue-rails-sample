class ActivityFeedbackNotification < Notification::BaseInternalActivityNotification
  store(
    :data,
    accessors: %i[
      ai_used
    ],
    coder: YAML
  )
  before_save :purge_no_dismissed_graded_and_feedback_notifications

  # Override the default accessor to always return either true or false.
  def ai_used
    !!super
  end

  def ai_used?
    ai_used
  end

  def message
    "Your #{audience_label(audience, :instructor)} added some feedback."
  end

  private def purge_no_dismissed_graded_and_feedback_notifications
    return unless section.present? && user.present?

    notifications = Notification.where(user_id: user.id, section_id: section.id)
                                .where('dismissed_at is null AND (type=? OR type=?)',
                                       'ActivityFeedbackNotification',
                                       'ActivityGradedNotification')
                                .newest_first
    notifications.each do |notification|
      unless notification.activity.id != activity.id || notification.id == id
        notification.destroy
      end
    end
  end
end
