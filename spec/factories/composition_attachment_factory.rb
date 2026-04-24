FactoryBot.define do
  factory :composition_attachment do
    created_at { Date.today }
    sequence(:file_name) { |n| "some_file_#{n}.txt" }
    association :user, factory: :user
  end

  factory :expired_draft_attachment, parent: :composition_attachment do
    created_at { 3.days.ago }
  end

  factory :no_draft_attachment, parent: :composition_attachment do
    draft { false }
  end
end
