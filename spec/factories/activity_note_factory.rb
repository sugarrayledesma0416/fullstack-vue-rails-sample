FactoryBot.define do
  factory :activity_note do
    association :focused_course, factory: :course
    activity
    body_text { 'factory body text' }
    instructor
    program
    note_type { 'sidebar' }
  end
end
