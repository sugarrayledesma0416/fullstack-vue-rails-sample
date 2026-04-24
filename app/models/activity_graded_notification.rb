class ActivityGradedNotification < Notification::BaseInternalActivityNotification
  include Purgeable

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
