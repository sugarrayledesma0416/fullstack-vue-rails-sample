# Even though we aren't creating any new instances of these notifications

# since switching to the new gradebook, this class is being preserved to
# avoid breaking single-table inheritance and throwing errors when displaying
# student dashboards and notification lists for users who still have instances
# of these notifications.
class ActivityResetWorkNotification < Notification::BaseInternalActivityNotification
  def self.unwarned?(user, section, activity)
    undismissed.by_user_and_section(user, section).where(activity_id: activity.id).exists?
  end

  def message
    "Your #{audience_label(audience, :instructor)} reset this activity " \
    'so you can do it over.'
  end
end
