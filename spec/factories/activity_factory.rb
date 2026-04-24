# encoding: utf-8
FactoryBot.define do
  sequence(:cms_revision_id) { |n| n }

  factory :activity do
    sequence(:title) do |n|
      titles = ["Saludos", "Conversación", "Saludos, despedidas y presentaciones", "Los países", "¿Masculino o femenino?", "¿El, la, los o las?", "Singular y plural", "Las cosa", "Los pronombres", "Nosotros somos...", "¡Todos a bordo!", "¿De quién es?"]
      "#{n % 5 + 1} - #{titles[n % titles.length]}"
    end
    association :concept, factory: :concept_with_calculated_combined_rank
    lesson
    sequence(:cms_activity_id) { |n| n }
    cms_revision_id { generate(:cms_revision_id) }
    sequence(:concept_rank) { |n| n }
    sequence(:toc_location_rank) { |n| n }
    sequence(:toc_location) { |n| n }
    sequence(:points_possible) { |n| n % 10 + 10 }
    component_name { 'Workbook' }
    component_language { 'en' }
    max_attempts { 1 }
    license_group_id { 1 }
    submittable { true }
    cdn { false }
  end

  factory :activity_with_component, parent: :activity do
    component_name { 'factory component name' }
  end

  factory :activity_with_assignment_group, parent: :activity do
    assignment_group { 'Practice' }
  end

  factory :instructor_graded_activity, parent: :activity do
    content { '<activity activity_type="open_ended" title=""><dl></dl><items><item><prompt/></item></items></activity>' }
  end

  factory :partner_chat_activity, parent: :activity do
    activity_type { 'partner_chat' }
  end

  factory :group_chat_activity, parent: :activity do
    activity_type { 'group_chat' }
  end

  factory :solo_video_recording_activity, parent: :activity do
    activity_type { 'solo_video_recording' }
  end

  factory :activity_with_program, parent: :activity  do
    association :lesson, factory: :lesson_with_unit
  end

  factory :instructor_generated_activity, parent: :activity do
    cms_revision_id { nil }
    instructor_revision_id { generate(:cms_revision_id) }
  end

  factory :activity_with_json_content, parent: :activity do
    content do
      File.read(File.join('spec', 'fixtures', 'json', 'assessment_builder.json'))
    end
  end

  factory :json_activity_with_audio_prompt, parent: :activity do
    content do
      File.read(File.join('spec', 'fixtures', 'json', 'assessment_builder_with_audio_prompt.json'))
    end
  end

  factory :json_activity_with_passage, parent: :activity do
    content do
      File.read(File.join('spec', 'fixtures', 'json', 'assessment_builder_with_passage.json'))
    end
  end

  factory :json_activity_with_list, parent: :activity do
    content do
      File.read(File.join('spec', 'fixtures', 'json', 'assessment_builder_with_list.json'))
    end
  end
  
  factory :json_activity_with_table, parent: :activity do
    content do
      File.read(File.join('spec', 'fixtures', 'json', 'assessment_builder_with_table.json'))
    end
  end

  factory :json_activity_with_model, parent: :activity do
    content do
      File.read(File.join('spec', 'fixtures', 'json', 'assessment_builder_with_model.json'))
    end
  end

  factory :json_assessment_for_assessment_info, parent: :activity do
    content do
      File.read(File.join('spec', 'fixtures', 'json', 'json_assessment_for_assessment_info.json'))
    end
  end

  factory :json_assessment_with_svr, parent: :activity do
    content do
      File.read(File.join('spec', 'fixtures', 'json', 'json_assessment_with_svr.json'))
    end
  end
end
