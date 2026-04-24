class NotificationsPresenter
  NOTIFICATION_TOP = { vol: 10, super_site: 5 }.freeze

  attr_accessor :program, :section, :user

  def initialize(user, section, program)
    self.user = user
    self.section = section
    self.program = program
  end

  def notifications_and_announcements
    {
      activity_notifications: activity_notifications,
      announcement_notifications: announcement_notifications
    }
  end

  private def activity_notifications
    Notification.find_unique_activity_notifications(user, section).take(limit)
  end

  private def announcement_notifications
    Notification.find_unread_announcement_notifications(user, section).take(limit)
  end

  private def limit
    NOTIFICATION_TOP[program_type]
  end

  private def program_type
    program.vista_online_learning? ? :vol : :super_site
  end
end
