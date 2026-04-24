class ChangedEarnedScoreNotification < Notification::BaseInternalActivityNotification
  store(
    :data,
    accessors: %i[
      old_score
      new_score
      points_possible
    ],
    coder: YAML
  )
  before_create :denormalize_score_attributes

  attr_accessor :old_points_earned, :new_points_earned

  private def denormalize_score_attributes
    self.old_score = earned_percent(old_points_earned, points_possible)
    self.new_score = earned_percent(new_points_earned, points_possible)
  end

  def message
    "Your #{audience_label(audience, :instructor)} changed your score " \
    "from #{old_score}% to #{new_score}%."
  end
end
