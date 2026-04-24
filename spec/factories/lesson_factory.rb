FactoryBot.define do
  factory :lesson do
    name {|a| "Lesson #{a.rank}"}
    rank { 1 }
    unit
  end

  factory :lesson_with_toc_entries, parent: :lesson do
    toc_entries do |proxy|
      [].fill(0..5) { proxy.association(:two_layers_of_toc_entry) }
    end
  end

  factory :lesson_with_assessment_toc_entries, parent: :lesson do
    toc_entries do |proxy|
      [].fill(0..5) { proxy.association(:assessment_toc_entry) }
    end
  end

  factory :lesson_with_activities, parent: :lesson do
    toc_entries do |proxy|
      [proxy.association(:two_layers_of_toc_entries_with_activities)]
    end
  end

  factory :lesson_with_unit, class: :lesson do
    unit
  end

  factory :current_events_lesson, class: :lesson do
    association :unit, factory: :current_events_unit
  end

  factory :lesson_with_strands_and_activities, parent: :lesson do
    toc_entries { FactoryBot.create_list(:toc_entry, 2) }
    after(:build) do |lesson|
      activities = [ build(:activity, :lesson => lesson, :toc_location => lesson.toc_entries[0].location),
                     build(:activity, :lesson => lesson, :toc_location => lesson.toc_entries[1].location) ]
    end
    after(:create) do |lesson|
      lesson.activities.each {|activity| activity.save! }
    end
  end

  factory :lesson_with_strands_substrands_and_activities, parent: :lesson do
    toc_entries { FactoryBot.create_list(:two_layers_of_toc_entry, 2) }
    after(:build) do |lesson|
      activities = [ build(:activity, :lesson => lesson, :toc_location => lesson.toc_entries[0].children.first.location),
                     build(:activity, :lesson => lesson, :toc_location => lesson.toc_entries[1].children.first.location) ]
    end
    after(:create) do |lesson|
      lesson.activities.each {|activity| activity.save! }
    end
  end

  factory :lesson_with_strands_substrands, parent: :lesson do
    toc_entries { FactoryBot.create_list(:two_layers_of_toc_entry, 2) }
  end
end
