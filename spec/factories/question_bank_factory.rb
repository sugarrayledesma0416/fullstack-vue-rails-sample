FactoryBot.define do
  factory :question_bank do
    association :question_bank_topic
    cdn { false }
    cms_revision_id { nil }
    instructor_revision_id { nil }
    license_group_id { 1 }
    question_bank_revision_id { generate(:cms_revision_id) }
    sequence(:title) { |index| "Question Bank #{(index + 1)}" }
  end
end
