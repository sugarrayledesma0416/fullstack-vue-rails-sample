FactoryBot.define do
  factory :group_set do
    sequence(:name) { |n| "Group Set #{n}" }
  end
end
