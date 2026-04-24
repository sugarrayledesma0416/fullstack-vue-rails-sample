FactoryBot.define do
  factory :course_library_activity do
    course
    activity
    hidden { false }
  end
end
