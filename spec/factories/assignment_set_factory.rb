FactoryBot.define do
  factory :assignment_set do
    due_date { Date.today }
    association :section, factory: :section_with_course
  end
end
