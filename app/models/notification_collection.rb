class NotificationCollection
  include DateTimeHelper

  attr_accessor :program, :section, :user

  def initialize(program, section, user)
    self.program = program
    self.section = section
    self.user = user
  end

  def serialize
    user_notifications.each_with_object(empty_collection) do |entry, memo|
      memo[type_key(entry)][sub_key(entry)] << notification_entry(entry)
    end
  end

  private def type_key(entry)
    if entry.announcement_id
      :announcements
    else
      :notifications
    end
  end

  private def sub_key(entry)
    if entry.dismissed_at
      :viewed
    else
      :new
    end
  end

  private def empty_collection
    {
      announcements: { new: [], viewed: [] },
      notifications: { new: [], viewed: [] }
    }
  end

  private def notification_entry(notification)
    {
      class_cancelled: class_cancelled?(notification),
      created_at: format_date_time(notification.created_at, :gradebook_cell),
      id: notification.id,
      label: notification.label.strip_tags.html_decode,
      language: program.language_code,
      message: notification.message,
      path: notification.path
    }
  end

  private def class_cancelled?(notification)
    # The guard conditions are necessary because calling .announcement on
    # a non-announcement notification will raise a NoMethodError.
    # Using !foo.nil? instead of just foo to ensure that the return
    # value is always a boolean, and not nil, to avoid serializing
    # nil to JSON.
    !notification.announcement_id.nil? &&
    !notification.announcement.nil? &&
    notification.announcement.class_cancelled?
  end

  private def user_notifications
    Notification.by_user_and_section(user, section).newest_first
  end
end
