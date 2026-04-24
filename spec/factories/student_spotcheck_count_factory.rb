FactoryBot.define do
  factory :student_spotcheck_count do
    user
    section
    count { 10 }
  end
end
