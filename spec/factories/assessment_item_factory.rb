FactoryBot.define do
  factory :assessment_item do
    guid { SecureRandom.uuid }
    assessment_id { 123456 }
    points_possible { 2 }
  end

  factory :assessment_item_with_assessment, parent: :assessment_item do
    association :assessment, factory: :activity_with_json_content
  end
end

