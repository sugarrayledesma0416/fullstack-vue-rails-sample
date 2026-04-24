class StudyPlanConcept < ApplicationRecord
  belongs_to :activity
  belongs_to :program
  has_many :recommendations,
           class_name: 'StudyPlanConceptRecommendation',
           dependent: :destroy,
           foreign_key: :study_plan_concept_id,
           inverse_of: :study_plan_concept
  has_many :supplemental_recommendations,
           -> { supplemental },
           class_name: 'StudyPlanConceptRecommendation',
           dependent: :destroy,
           foreign_key: :study_plan_concept_id,
           inverse_of: :study_plan_concept

  accepts_nested_attributes_for :recommendations, allow_destroy: true

  validates :activity_id, :cms_revision_id, :program_id, presence: true

  def sorted_recommendations
    return recommendations unless need_sorting?

    recommendations.partition do |recommendation|
      recommendation.recommendation_type == 'vocabulary'
    end.flatten
  end

  def diagnostic_concept
    return unless activity.content_object.respond_to?(:concepts)

    activity.content_object&.concepts&.find { |c| c.ref == reference_id }
  end

  private def need_sorting?
    recommendations.any? { |recommendation| recommendation.recommendation_type == 'vocabulary' } &&
    recommendations.first.recommendation_type != 'vocabulary'
  end
end
