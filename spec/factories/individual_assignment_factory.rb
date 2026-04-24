FactoryBot.define do
  factory :individual_assignment do
    association :activity
    association :section
    association :user
    due_date { 7.days.from_now }
  end
end
