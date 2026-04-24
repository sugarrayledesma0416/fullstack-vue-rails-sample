FactoryBot.define do
  sequence :concept_name do |n|
    names = %w(Contextos Estructura Panorama Pronuncuacion Vocabulario Fotonovela)
    names[n % names.length]
  end

  factory :concept_with_calculated_combined_rank, parent: :concept do
    lesson_combined_rank { lesson.unit.rank.to_i * 100 + lesson.rank.to_i + 1 }
  end

  factory :concept do
    name { generate(:concept_name) }
    breadcrumb_string { 'Lesson 1 - La Familia' }
    background_color { '#aabbcc' }
    association :lesson, factory: :lesson_with_unit
    program
    rank { 1 }
    lesson_combined_rank { 1 }
  end

  factory :concept_with_activities, parent: :concept do
    activities {|proxy| [].fill(0..2) {proxy.association(:activity)}}
  end

  factory :concept_for_quiz, parent: :concept do
    name { 'Grammar Quiz' }
    assessment { true }
    singular_label { 'quiz' }
  end

  factory :concept_for_test, parent: :concept do
    name { 'Unit Test' }
    assessment { true }
    singular_label { 'test' }
  end
end
