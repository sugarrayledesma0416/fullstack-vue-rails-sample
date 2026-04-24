FactoryBot.define do
  factory :section_instructor do
    role { 'Instructor' }
    section
    instructor
  end

  factory :section_co_instructor, parent: :section_instructor do
    role { SectionInstructor::INSTRUCTOR_ROLES[:co_instructor] }
  end

  factory :section_assistant, parent: :section_instructor do
    role { SectionInstructor::INSTRUCTOR_ROLES[:assistant] }
  end
end
