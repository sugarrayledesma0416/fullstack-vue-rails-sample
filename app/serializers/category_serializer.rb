class CategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :weighting_percent, :errors, :has_assignments, :rank, :penalty_percent,
             :late_work_penalty, :max_attempts, :credit_only, :enhanced_feedback_disabled,
             :accept_late_work, :drop_low_scores
  has_one :current_scoring_ruleset

  def errors
    object.errors.empty? ? [] : object.errors.full_messages
  end

  def has_assignments
    object.has_assignments?
  end
end
