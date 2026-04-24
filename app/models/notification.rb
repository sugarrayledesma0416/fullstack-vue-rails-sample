class Notification < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :user
  belongs_to :section

  self.inheritance_column = 'type'

  scope :newest_first, -> { order('notifications.id DESC') }
  scope :by_section, ->(section) { where(section_id: section) }
  scope :for_activities, -> { where('activity_id is not null') }
  scope :for_announcements, -> { where('announcement_id is not null') }
  scope :undismissed, -> { where(dismissed_at: nil).extending(Notification::Destroyable) }
  scope :dismissed, -> { where('dismissed_at is not null') }
  scope :by_user_and_section, (
    lambda do |user, section|
      where(user_id: user, section_id: section)
        .extending(Notification::Dismissable, Notification::Destroyable)
    end
  )

  def self.communications(user, section, communication_type, dismissal_state)
    builder = by_user_and_section(user, section)

    builder = if communication_type == 'announcements'
                builder.for_announcements
              else
                builder.for_activities
              end

    builder = if dismissal_state == 'dismissed'
                builder.dismissed
              else
                builder.undismissed
              end

    builder.newest_first
  end

  def label
    raise NotImplementedError
  end

  def dismiss
    dismissed_attrs = {
      dismissed: true
    }.tap do |memo|
      memo[:dismissed_at] = Time.zone.now unless dismissed?
    end
    update(dismissed_attrs)
  end

  def dismissed?
    !dismissed_at.nil?
  end

  def path
    section_notification_path(section_id, id)
  end

  def self.find_unique_activity_notifications(user_id, section_id)
    by_user_and_section(user_id, section_id)
      .for_activities
      .undismissed
      .group('activity_id')
      .newest_first
  end

  def self.find_unread_announcement_notifications(user_id, section_id)
    by_user_and_section(user_id, section_id).for_announcements.undismissed.newest_first
  end

  class BaseActivityNotification < Notification
    include AudienceLabeling

    store(
      :data,
      accessors: %i[
        activity_title
        is_assessment
        lesson_label
        strand_name
        student_display_title
      ],
      coder: YAML
    )
    before_create :denormalize_activity_attributes

    def label(location_only = false)
      if is_assessment
        student_display_title
      else
        label_text = [lesson_label, strand_name]
        label_text << activity_title unless location_only
        label_text.compact_blank.join(' | ')
      end
    end

    private def audience
      section&.program&.audience || :default
    end

    private def denormalize_activity_attributes
      self.lesson_label = activity.lesson_label
      self.strand_name = activity.lesson && activity.strand && activity.strand.name
      self.activity_title = activity.title
      self.is_assessment = activity.assessment?
      self.student_display_title = activity.student_display_title
    end

    private def score_for_activity
      return 0 unless activity.present? && section.present?
      score = find_score(
        activity_id: activity.id,
        section_id: section.id,
        user_id: user.id
      )
      score && earned_percent(score.points_earned, score.points_possible) || 0
    end

    private def earned_percent(points_earned, points_possible)
      if points_earned.nil?
        0.0
      else
        ((points_earned / points_possible) * 100).to_i
      end
    end
  end

  class BaseInternalActivityNotification < BaseActivityNotification
    belongs_to :activity
    validates_presence_of :activity

    private def find_score(args)
      GradebookEngine::GradebookAPI.find_score(**args)
    end

    def redirect_type
      :internal_activity
    end
  end

  module Dispatchable
    # association extension, to use, define association such as:
    # has_many :notifications, :extend => Notification::Dispatchable
    # then you can call:
    # notifications.dispatch('NotificationType', {:user => user, :section => section})
    def dispatch(notification_type, opts)
      # TODO: Validate notification type is valid for current proxy_owner
      #       e.g.   Activities shouldn't allow announcement notifications.
      proxy_association.concat("#{notification_type}Notification".constantize.new(opts))
    end
  end

  module Dismissable
    # named scope extension, to use, define scope such as:
    # scope :by_section, :extend => Notification::Dismissable
    # then you can call:
    # notifications.by_section.dismiss_all!
    def dismiss_all!
      each(&:dismiss)
    end
  end

  module Destroyable
    # named scope extension, to use, define scope such as:
    # scope :by_section, :extend => Notification::Destroyable
    # then you can call: notifications.by_section.destroy!
    # We have to iterate through these instead of calling clear or destroy_all
    # because those methods will affect all associated objects, not just those selected by a
    # particular named scope. e.g. announcement.notifications.undismissed.destroy_all
    # will delete both dismissed and undimissed notifications.
    def destroy!
      each(&:destroy)
    end
  end

  module Purgeable
    def self.included(klass)
      klass.class_eval do
        before_save :purge_old_notifications
      end
    end

    def destroyable?(activity_id, notification_id)
      (activity && activity.id == activity_id && notification_id != id)
    end

    def purge_old_notifications
      return unless section.present? && user.present?
      self.class.by_user_and_section(user.id, section.id).each do |notification|
        notification.destroy if notification.destroyable?(activity.id, id)
      end
    end
    private :purge_old_notifications
  end
end
