FactoryBot.define do
  factory :study_plan_concept do
    activity
    program
    cms_revision_id { 1 }
    sequence(:reference_id) { |n| "1.#{n}" }
    sequence(:title) { |n| "Concept #{n}" }
    threshold { 70 }
    created_at { Date.today }
  end
end
