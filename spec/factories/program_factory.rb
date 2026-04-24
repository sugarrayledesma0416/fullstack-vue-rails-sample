FactoryBot.define do
  factory :program do
    sequence(:title) { |index| "program #{index}" }
    image_filename { 'new_book.png' }
    prefix_abbreviation { 'abbr2e' }
    maestro_version { 3 }
    unit_label { 'Unit' }
    lesson_label { 'Lesson' }
    language_code { 'es' }
  end

  factory :vol_program, parent: :program do
    title { 'Portales' }
    image_filename { 'portales1.png' }
    prefix_abbreviation { 'port1e' }
    unit_label { 'Lesson' }
    family { 'vista_online_learning' }
  end

  factory :ss_jr_program, parent: :program do
    title { 'Get Ready' }
    image_filename { 'new_book.png' }
    prefix_abbreviation { 'gr1e' }
    unit_label { 'Lesson' }
    family { 'supersites_jr' }
  end

  factory :m2_program, parent: :program do
    maestro_version { 2 }
    vhlcentral_subdomain { 'factory-domain' }
  end

  factory :maestro2_program, parent: :m2_program do
  end

  factory :vol_program_with_lessons, parent: :vol_program do
    after(:create) do |program|
      create(:unit_with_lessons, :use_type => 'Unit', :program => program)
    end
    after(:build) do |program|
      build(:unit_with_lessons, :use_type => 'Unit', :program => program)
    end
    after(:build_stubbed) do |program|
      build_stubbed(:unit_with_lessons, :use_type => 'Unit', :program => program)
    end
  end

  factory :program_with_lessons, parent: :program do
    after(:create) do |program|
      3.times { |number| create :unit_with_lessons, :rank => number+1, :use_type => 'Unit', :program => program }
    end
    after(:build) do |program|
      3.times { |number| build(:unit_with_lessons, :rank => number+1, :use_type => 'Unit', :program => program) }
    end
    after(:build_stubbed) do |program|
      3.times { |number| build_stubbed(:unit_with_lessons, :rank => number+1, :use_type => 'Unit', :program => program) }
    end
  end

  factory :program_with_lessons_and_resource_units, parent: :program do
    after(:create) do |program|
      program.units_and_resource_units = Array.new(3) do |number|
        create(:unit_with_lesson, rank: number + 1, program: program)
      end
    end
    after(:build) do |program|
      program.units_and_resource_units = Array.new(3) do |number|
        build(:unit_with_lesson, rank: number + 1, program: program)
      end
    end
    after(:build_stubbed) do |program|
      program.units_and_resource_units = Array.new(3) do |number|
        build_stubbed(:unit_with_lesson, rank: number + 1, program: program)
      end
    end
  end

  factory :program_with_toc_entries, parent: :program do
    after(:create) do |program|
      program.units = Array.new(3) do |number|
        create(
          :unit_with_lesson_with_toc_entries,
          rank: number + 1,
          program: program
        )
      end
    end
    after(:build) do |program|
      program.units = Array.new(3) do |number|
        build(
          :unit_with_lesson_with_toc_entries,
          rank: number + 1,
          program: program
        )
      end
    end
    after(:build_stubbed) do |program|
      program.units = Array.new(3) do |number|
        build_stubbed(
          :unit_with_lesson_with_toc_entries,
          rank: number + 1,
          program: program
        )
      end
    end
  end

  factory :program_with_assessment_toc_entries, parent: :program do
    after(:create) do |program|
      program.units = Array.new(3) do |number|
        create(
          :unit_with_lessons_with_assessment_toc_entries,
          rank: number + 1,
          program: program
        )
      end
    end
    after(:build) do |program|
      program.units = Array.new(3) do |number|
        build(
          :unit_with_lessons_with_assessment_toc_entries,
          rank: number + 1,
          program: program
        )
      end
    end
    after(:build_stubbed) do |program|
      program.units = Array.new(3) do |number|
        build_stubbed(
          :unit_with_lessons_with_assessment_toc_entries,
          rank: number + 1,
          program: program
        )
      end
    end
  end

  factory :vol_program_with_toc_entries, parent: :vol_program do
    units do |proxy|
      [].fill(0..2) { |number| proxy.association(:unit_with_lesson_with_toc_entries, rank: number+1) }
    end
  end

  factory :program_with_activities, parent: :program do
    units do |proxy|
      [].fill(0..2) { |number| proxy.association(:unit_with_lesson_with_activities, rank: number+1) }
    end
  end

  factory :two_tier_program_with_toc_entries, parent: :program do
    units do |proxy|
      [].fill(0..2) { |number| proxy.association(:unit_with_lessons_with_toc_entries, rank: number+1) }
    end
  end

  factory :two_tier_program_with_unit_in_lesson_names, parent: :program do
    after(:build) do |program|
      program.units = Array.new(3) do |number|
        build(
          :unit_with_lessons_with_toc_entries_and_unit_in_name,
          rank: number + 1,
          program: program
        )
      end
    end
    after(:build_stubbed) do |program|
      program.units = Array.new(3) do |number|
        build_stubbed(
          :unit_with_lessons_with_toc_entries_and_unit_in_name,
          rank: number + 1,
          program: program
        )
      end
    end
  end
end
