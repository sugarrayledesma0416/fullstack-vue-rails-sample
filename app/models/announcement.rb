class Announcement < ApplicationRecord
  include Radner::FilesS3Bucket

  default_scope { where(is_archived: false).order('announcements.created_at DESC') }

  has_many :notifications,
           class_name: 'AnnouncementPostedNotification',
           extend: Notification::Dispatchable

  # inverse_of is needed because of accepted_nested_attributes
  has_many :announcement_sections,
           dependent: :destroy,
           inverse_of: :announcement
  has_many :sections, through: :announcement_sections

  # inverse_of is needed because of the non-standard class/foreign_key
  belongs_to :author,
             class_name: 'User',
             foreign_key: 'author_id',
             inverse_of: :announcements

  scope :by_section, lambda {|*sections| includes(:announcement_sections)
    .joins(:announcement_sections)
    .where(announcement_sections: {section_id: sections})
  }
  validate :external_link_url_syntax
  before_save :sanitize_file_name

  after_save :update_announcement_notifications
  accepts_nested_attributes_for :announcement_sections, allow_destroy: true

  validates_presence_of :author_id
  validates_presence_of :title

  def self.by_month_and_calendar_day(sections, month_number)
    # Scope *by_section* can't be used here since the 'includes(:announcement_sections)' clause messes with the select part of this query

    # ensure sections param can be consumed properly by active record
    sections = (sections.respond_to?(:map) ? sections.map(&:id) : sections)
    select('announcements.id, announcements.show_on, MAX(announcements.class_cancelled) AS any_class_cancelled, ' \
           'COUNT(DISTINCT(announcements.id)) AS announcement_count')
    .joins(:announcement_sections)
    .where(announcement_sections: {section_id: sections})
    .where("MONTH(announcements.show_on) = ?", month_number)
    .group('announcements.show_on')
    .inject({}){|m,v| m[v.show_on] = v; m }
  end

  def self.create_missing_notifications_for_student_in_section(student, section)
    by_section(*section).each do |announcement|
      announcement.create_notification_if_missing(student, section)
    end
  end

  def dismiss_notifications_for_user_and_section(user, section)
    notifications.undismissed.by_user_and_section(user, section).dismiss_all!
  end

  def create_notification_if_missing(student, section_to_notify)
    # Can't just use self.section, because we could have an announcement for a course
    # with no section_id set.
    unless notifications.by_user_and_section(student, section_to_notify).any?
      notifications.create!(section: section_to_notify, user: student)
    end
  end

  def update_announcement_notifications
    if is_archived?
      notifications.destroy_all
    else
      transaction do
        notifications.undismissed.destroy!
        sections.each do |section_to_notify|
          create_notifications_for_section(section_to_notify)
        end
      end
    end
  end
  private :update_announcement_notifications

  def create_notifications_for_section(section_to_notify)
    section_to_notify.current_students_base.each do |student|
      notifications.create!(section: section_to_notify, user: student)
    end
  end
  private :create_notifications_for_section

  ### Remove before merging! ###
  def has_file?
    has_file_name?
  end

  def file_path
    return '' unless has_file_name?
    File.join('announcements', M3::Application.config.current_deployed_env_name,
              id.to_s, file_name)
  end

  # This code should be refactored to use the ExternalUrlValidator in the lib/validators folder
  def external_link_url_syntax
    return if external_link_url.blank?
    current_url = external_link_url
    current_url = "http://#{current_url}" if incorrect_or_missing_protocol?(current_url)
    if url_is_invalid?(current_url)
      errors.add(:external_link_url, 'is invalid')
    else
      self.external_link_url = current_url
    end
  end
  private :external_link_url_syntax

  def incorrect_or_missing_protocol?(url_str)
    !(url_str =~ /\A(http:\/\/)|(https:\/\/)|(ftp:\/\/)/)
  end
  private :incorrect_or_missing_protocol?

  def url_is_invalid?(url_str)
    !(url_str =~ /^(http|https|ftp):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix)
  end
  private :url_is_invalid?
end
