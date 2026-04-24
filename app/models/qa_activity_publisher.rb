class QaActivityPublisher
  attr_accessor :activity_id, :content_xml, :error, :filepath, :old_cdn, :old_content

  def initialize(activity_id, content_xml)
    self.activity_id = activity_id
    self.content_xml = content_xml
  end

  def publish
    # rubocop:disable Rails/UnknownEnv
    raise 'Do not run on a live server!' if Rails.env.live?
    # rubocop:enable Rails/UnknownEnv

    activity = Activity.find(activity_id)
    store_old_values(activity)

    activity.update!(cdn: false) if activity.cdn?

    store_new_content

    self
  end

  private def rollback(message)
    self.error = message

    activity = Activity.find(activity_id)
    if old_cdn
      activity.update!(cdn: true)
    else
      activity.activity_content.store_content(old_content)
    end
  end

  private def store_new_content
    activity = Activity.find(activity_id)
    self.filepath = activity.content_filepath
    FileUtils.makedirs(File.dirname(filepath))
    File.write(filepath, content_xml)
    verify_content
  end

  private def store_old_values(activity)
    self.old_cdn = activity.cdn?
    self.old_content = activity.content
  end

  private def verify_content
    activity = Activity.find(activity_id)
    content_object = activity.content_object
    if content_object.nil?
      rollback(activity.parse_errors.inspect)
    else
      activity.update!(title: content_object.title)
    end
  end
end
