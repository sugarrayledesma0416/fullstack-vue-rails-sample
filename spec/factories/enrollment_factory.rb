FactoryBot.define do
  factory :enrollment do
    association :user, factory: :student
    section
    state { 'enrolled' }
  end

  factory :active_enrollment, parent: :enrollment do
    association :section, factory: :section_with_course
    state { 'enrolled' }
  end

  factory :dropped_enrollment, parent: :enrollment do
    state { 'dropped' }
    dropped_at { 1.day.ago }
    dropped_by_id { 1 }
  end

  factory :transferred_enrollment, parent: :enrollment do
    state { 'transferred' }
  end

  factory :completed_enrollment, parent: :enrollment do
    state { 'marked_complete' }
  end

  factory :closed_course_enrollment, parent: :enrollment do
    state { 'enrolled' }
    association :section, factory: :section_in_closed_course
  end

  factory :open_course_enrollment, parent: :enrollment do
    state { 'enrolled' }
    association :section, factory: :section_in_open_course
  end

  factory :enrollment_in_archived_section, parent: :enrollment do
    association :section, factory: :archived_section_in_archived_course
  end

  factory :enrollment_with_access, parent: :enrollment do
    sufficient_access { true }
  end
end
