FactoryBot.define do
  factory :program_config do
    program
    association :creator, factory: :user
    settings { {} }
  end

  factory :vol_program_config, parent: :program_config do
    association :program, factory: :vol_program
    course_setup_descriptions do
      {
        express_course: 'Things fast',
        advanced_course: 'Things slow',
        learning_tracks: {
          header: 'Learning tracks',
          general: 'General learning track description.',
          options_overall: 'Learning track options description.',
          options: [
            {
              label: 'Essentials',
              explanation: 'What option 1 covers'
            },
            {
              label: 'Complete',
              explanation: 'What option 2 covers'
            }
          ]
        }
      }
    end
  end

  factory :practice_test_analytics_program_config, parent: :program_config do
    practice_test_analytics_enabled { true }
  end

  factory :program_config_with_standard_sets, parent: :program_config do
    transient do
      supported_standard_sets { [create(:standard_set), create(:standard_set)] }
      min_grade { 'K' }
      max_grade { '12' }
    end

    standards_settings do
      {
        supported_standard_set_ids: supported_standard_sets.map(&:id).map(&:to_s),
        min_grade:,
        max_grade:
      }
    end
    pmr_standard_reports_allowed { true }
  end

  factory :program_config_with_std_sets_and_skills_refinements, parent: :program_config_with_standard_sets do
    show_skills_and_refinement_filters { true }
  end

  factory :program_config_with_ai_grading, parent: :program_config do
    ai_settings do
      {
        grading_suggestions: true,
        program_level: 'introductory'
      }
    end
  end
end
