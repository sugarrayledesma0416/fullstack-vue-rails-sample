class ActivityNote < ApplicationRecord
  include RecordingPath

  belongs_to :activity
  belongs_to :focused_course, class_name: 'Course', optional: true
  belongs_to :instructor, foreign_key: 'user_id'
  belongs_to :program
  belongs_to :recording, optional: true
  belongs_to :video_recording, optional: true

  validate :presence_of_content

  scope :by_activity, ->(activity) { where(activity_id: activity) }
  scope :by_instructor, ->(instructor) { where(user_id: instructor) }

  def presence_of_content
    if text_without_tags.blank? && recording_path.blank? && video_recording_path.blank?
      errors.add('Recording or body text', 'are required.')
    end
  end
  private :presence_of_content

  def text_without_tags
    body_text.to_s.gsub('&nbsp;', '').strip_tags.strip
  end
  private :text_without_tags

  def video_recording_path=(path)
    update_associated_recording('video_recording', path)
  end

  def video_recording_path
    get_recording_path_for('video_recording')
  end

  def recording_path
    recording && recording.recording_path
  end

  def as_json(options = {})
    super(
      options.merge(
        methods: [:recording_path, :video_recording_path]
      )
    )
  end
end
