# Even though we aren't creating any new instances of these notifications
# since switching to the new gradebook, this class is being preserved to
# avoid breaking single-table inheritance and throwing errors when displaying
# student dashboards and notification lists for users who still have instances
# of these notifications.
class ActivityQuickGradedNotification < Notification::BaseInternalActivityNotification
  include Notification::Purgeable

  store(
    :data,
    accessors: %i[
      score
    ],
    coder: YAML
  )
  before_create :denormalize_score_for_activity

  def message
    "Your #{audience_label(audience, :instructor)} graded this activity, " \
    "giving you a score of #{score}%."
  end

  private def denormalize_score_for_activity
    self.score = score_for_activity
  end
end
