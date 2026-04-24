class ActivityLatePenaltyForScoreNotification < Notification::BaseInternalActivityNotification
  store(
    :data,
    accessors: %i[
      new_penalty_percent
      old_penalty_percent
    ],
    coder: YAML
  )

  def message
    "Your #{audience_label(audience, :instructor)} changed the late " \
    "penalty percentage from #{old_penalty_percent}% to #{new_penalty_percent}%."
  end
end
