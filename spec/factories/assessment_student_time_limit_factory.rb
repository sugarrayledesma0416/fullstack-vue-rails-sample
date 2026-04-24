FactoryBot.define do
  factory :assessment_student_time_limit do
    sequence(:user_id) { |n| 10000 + n }
    sequence(:section_id) { |n| 100 + n }
    sequence(:activity_id) { |n| 1000 + n }
    time_limit { 120 }
  end
end
