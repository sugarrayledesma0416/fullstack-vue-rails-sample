FactoryBot.define do
  factory :assignment_filter do
    user
    course
  end

  factory :assignment_filter_by_lesson, parent: :assignment_filter do
    lesson_id { 1 }
  end
end
