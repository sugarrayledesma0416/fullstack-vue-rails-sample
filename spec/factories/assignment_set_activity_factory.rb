FactoryBot.define do
  sequence(:rank) { |n| n + 1 }

  factory :assignment_set_activity do
    assignment_set_rank { generate(:rank) }
    association :activity
    association :assignment_set
  end
end
