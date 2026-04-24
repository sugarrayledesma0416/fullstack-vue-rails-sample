FactoryBot.define do
  sequence :instructor_created_activity_title do |n|
    "Instructor Activity #{n}"
  end

  factory :instructor_created_activity do
    activity_type { 'composition' }
    component_name { 'Instructor-created Activities' }
    concept
    instructor
    lesson
    license_group_id { 1 }
    max_attempts { 1 }
    concept_rank { 0 }
    sequence(:instructor_revision_id) { |n| n }
    sequence(:points_possible) { |n| n % 10 + 10 }
    toc_location_rank { 0 }
    submittable { false }
    title { generate(:instructor_created_activity_title) }
  end

  # This factory includes non-database attributes that will break creating
  #   an actual database record. It may be used with :build and :build_stubbed.
  factory :instructor_created_activity_with_non_db_attrs, parent: :instructor_created_activity do
    direction_line { 'DL' }
    language_code { 'es' }
    question_prompt { 'QP' }
  end
end
