FactoryBot.define do
  factory :recommendation, class: StudyPlanConceptRecommendation do
    study_plan_concept
    cms_activity_id { 1 }
    sequence(:title) { |n| "Reading #{n}" }
    created_at { Time.zone.today }
    recommendation_type { 'reference' }
  end

  factory :vocabulary_recommendation, parent: :recommendation do
    recommendation_type { 'vocabulary' }
  end

  factory :supplemental_recommendation, parent: :recommendation do
    recommendation_type { 'supplemental' }
  end
end
