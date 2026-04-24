FactoryBot.define do
  factory :unit do
    rank { 1 }
    name { |a| "Lesson #{a.rank}" }
    released { true }
    program
    use_type { 'Unit' }
  end

  factory :unit_with_lesson, parent: :unit do
    after(:create) do |factoryd_unit|
      create(
        :lesson,
        name: factoryd_unit.name,
        rank: factoryd_unit.rank,
        unit: factoryd_unit
      )
    end
    after(:build) do |unit|
      build(
        :lesson,
        name: unit.name,
        rank: unit.rank,
        unit: unit
      )
    end
    after(:build_stubbed) do |unit|
      build_stubbed(
        :lesson,
        name: unit.name,
        rank: unit.rank,
        unit: unit
      )
    end
  end

  factory :unit_with_lessons, parent: :unit do
    after(:create) do |factoryd_unit|
      create(
        :lesson,
        name: "Lesson #{factoryd_unit.rank * 2 - 1}",
        rank: factoryd_unit.rank * 2 - 1,
        unit: factoryd_unit
      )
      create(
        :lesson,
        name: "Lesson #{factoryd_unit.rank*2}",
        rank: factoryd_unit.rank * 2,
        unit: factoryd_unit
      )
    end
    after(:build) do |unit|
      build(
        :lesson,
        name: "Lesson #{unit.rank * 2 - 1}",
        rank: unit.rank * 2 - 1,
        unit: unit
      )
      build(
        :lesson,
        name: "Lesson #{unit.rank * 2}",
        rank: unit.rank * 2,
        unit: unit
      )
    end
    after(:build_stubbed) do |unit|
      build_stubbed(
        :lesson,
        name: "Lesson #{unit.rank * 2 - 1}",
        rank: unit.rank * 2 - 1,
        unit: unit
      )
      build_stubbed(
        :lesson,
        name: "Lesson #{unit.rank * 2}",
        rank: unit.rank * 2,
        unit: unit
      )
    end
  end

  factory :current_events_unit, parent: :unit_with_lesson do
    use_type { 'CurrentEvents' }
  end

  factory :unit_with_lesson_with_toc_entries, parent: :unit do
    after(:create) do |factoryd_unit|
      create(
        :lesson_with_toc_entries,
        name: factoryd_unit.name,
        rank: factoryd_unit.rank,
        unit: factoryd_unit
      )
    end
    after(:build) do |unit|
      build(
        :lesson_with_toc_entries,
        name: unit.name,
        rank: unit.rank,
        unit: unit
      )
    end
    after(:build_stubbed) do |unit|
      build_stubbed(
        :lesson_with_toc_entries,
        name: unit.name,
        rank: unit.rank,
        unit: unit
      )
    end
  end

  factory :unit_with_lessons_with_toc_entries, parent: :unit do
    after(:create) do |factoryd_unit|
      factoryd_unit.lessons = [
        create(
          :lesson_with_toc_entries,
          name: "Lesson #{factoryd_unit.rank * 2 - 1}",
          rank: factoryd_unit.rank * 2 - 1,
          unit: factoryd_unit
        ),
        create(
          :lesson_with_toc_entries,
          name: "Lesson #{factoryd_unit.rank * 2}",
          rank: factoryd_unit.rank * 2,
          unit: factoryd_unit
        )
      ]
    end
    after(:build) do |unit|
      unit.lessons = [
        build(
          :lesson_with_toc_entries,
          name: "lesson #{unit.rank * 2 - 1}",
          rank: unit.rank * 2 - 1,
          unit: unit
        ),
        build(
          :lesson_with_toc_entries,
          name: "lesson #{unit.rank * 2}",
          rank: unit.rank * 2,
          unit: unit
        )
      ]
    end
    after(:build_stubbed) do |unit|
      unit.lessons = [
        build_stubbed(
          :lesson_with_toc_entries,
          name: "lesson #{unit.rank * 2 - 1}",
          rank: unit.rank * 2 - 1,
          unit: unit
        ),
        build_stubbed(
          :lesson_with_toc_entries,
          name: "lesson #{unit.rank * 2}",
          rank: unit.rank * 2,
          unit: unit
        )
      ]
    end
  end

  factory :unit_with_lessons_with_assessment_toc_entries, parent: :unit do
    after(:create) do |factoryd_unit|
      factoryd_unit.lessons = [
        create(
          :lesson_with_assessment_toc_entries,
          name: "Lesson #{factoryd_unit.rank * 2 - 1}",
          rank: factoryd_unit.rank * 2 - 1,
          unit: factoryd_unit
        ),
        create(
          :lesson_with_assessment_toc_entries,
          name: "Lesson #{factoryd_unit.rank * 2}",
          rank: factoryd_unit.rank * 2,
          unit: factoryd_unit
        )
      ]
    end
    after(:build) do |unit|
      unit.lessons = [
        build(
          :lesson_with_assessment_toc_entries,
          name: "lesson #{unit.rank * 2 - 1}",
          rank: unit.rank * 2 - 1,
          unit: unit
        ),
        build(
          :lesson_with_assessment_toc_entries,
          name: "lesson #{unit.rank * 2}",
          rank: unit.rank * 2,
          unit: unit
        )
      ]
    end
    after(:build_stubbed) do |unit|
      unit.lessons = [
        build_stubbed(
          :lesson_with_assessment_toc_entries,
          name: "lesson #{unit.rank * 2 - 1}",
          rank: unit.rank * 2 - 1,
          unit: unit
        ),
        build_stubbed(
          :lesson_with_assessment_toc_entries,
          name: "lesson #{unit.rank * 2}",
          rank: unit.rank * 2,
          unit: unit
        )
      ]
    end
  end

  factory :unit_with_lessons_with_toc_entries_and_unit_in_name, parent: :unit do
    after(:create) do |unit|
      unit.lessons = [
        create(
          :lesson_with_toc_entries,
          name: "Unit #{unit.rank} Lesson 1",
          rank: 1,
          unit: unit
        ),
        create(
          :lesson_with_toc_entries,
          name: "Unit #{unit.rank} Lesson 2",
          rank: 2,
          unit: unit
        )
      ]
    end
    after(:build) do |unit|
      unit.lessons = [
        build(
          :lesson_with_toc_entries,
          name: "Unit #{unit.rank} Lesson 1",
          rank: 1,
          unit: unit
        ),
        build(
          :lesson_with_toc_entries,
          name: "Unit #{unit.rank} Lesson 2",
          rank: 2,
          unit: unit
        )
      ]
    end
  end

  factory :unit_with_lesson_with_activities, parent: :unit do
    lessons do |proxy|
      [proxy.association(:lesson_with_activities, name: proxy.name, rank: proxy.rank)]
    end
  end
end
