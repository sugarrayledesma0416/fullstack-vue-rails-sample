FactoryBot.define do
  factory :custom_rubric do
    association :instructor_created_activity, factory: :activity
    association :source_activity, factory: :activity
  end
end
