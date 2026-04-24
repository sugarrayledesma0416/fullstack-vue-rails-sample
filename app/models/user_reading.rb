class UserReading < ApplicationRecord
  belongs_to :recommendation, class_name: 'StudyPlanConceptRecommendation',
                              foreign_key: :study_plan_concept_recommendation_id,
                              inverse_of: :user_readings
  belongs_to :user

  has_one :study_plan_concept, through: :recommendation

  validates :user_id, :study_plan_concept_recommendation_id, presence: true

  delegate :supplemental_activity, :reference_activity, to: :recommendation

  delegate :title, to: :supplemental_activity, prefix: true, allow_nil: true
  delegate :title, to: :reference_activity, prefix: true, allow_nil: true

  def html_class_name
    viewed? ? '' : 'is-disabled'
  end

  def activity_title
    recommendation.title || reference_activity_title
  end
end
