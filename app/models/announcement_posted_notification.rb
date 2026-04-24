class AnnouncementPostedNotification < Notification
  belongs_to :announcement

  store(
    :data,
    accessors: %i[
      announcement_title
    ],
    coder: YAML
  )
  before_save :denormalize_announcement_title

  def message
    ''
  end

  def label
    announcement_title.to_s.strip_tags
  end

  def redirect_type
    :announcement
  end

  private def denormalize_announcement_title
    self.announcement_title = announcement.title
  end
end
