FactoryBot.define do
  factory :announcement do
    sequence(:title) { |n| "Factory Anouncement #{n}" }
    body { 'This is a factory announcement.' }
    created_at { Date.today }
    association :author, factory: :instructor
  end

  factory :announcement_section do
    announcement
    section
  end
end
