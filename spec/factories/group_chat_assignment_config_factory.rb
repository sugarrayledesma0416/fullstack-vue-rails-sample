FactoryBot.define do
  factory :group_chat_assignment_config do
    association :assignment, factory: :assignment
    group_minimum { 3 }
    group_maximum { 6 }
  end
end
