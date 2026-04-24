FactoryBot.define do
  sequence :section_name do |n|
    names = ['Section 1234', 'Section 2345', 'Section 3456', 'Section 505a', 'Section 505b']
    names[n % names.length]
  end

  sequence :schedule do |n|
    schedule = ['MN 9:00 AM', 'TU 2:30 PM', 'MWF 3:45 PM', 'TH 11:00 AM', 'FR 8:00 AM', 'WE 1:30 PM']
    schedule[n % schedule.length]
  end

  factory :section do
    name { 'factory section name' }
    schedule { 'TH 5:00 PM' }
    due_time { DateTime.civil(2011, 1, 1, 12, 0) }
    time_zone { 'Eastern Time (US & Canada)' }
    is_enterprise { false }
    instructor
    course do |proxy|
      proxy.association(:course, owner_id: proxy.instructor.id)
    end
    sequence(:guid) { |_n| SecureRandom.uuid }
    after(:create) do |section|
      unless section.is_enterprise?
        create(:section_instructor, section:, instructor: section.instructor, role: 'Instructor')
      end
    end

    after(:build) do |section|
      if section.is_enterprise? && section.class_days.blank?
        section.class_days = '1, 3, 5'
      end
    end
  end

  factory :section_without_section_instructor_callback, class: :section do
    name { 'factory section name' }
    schedule { 'TH 5:00 PM' }
    due_time { DateTime.civil(2011, 1, 1, 12, 0) }
    time_zone { 'Eastern Time (US & Canada)' }
    instructor
    sequence(:guid) { |_n| SecureRandom.uuid }
  end

  factory :section_with_course, parent: :section do
    instructor
    course do |proxy|
      proxy.association(:course, owner_id: proxy.instructor.id)
    end
  end

  factory :example_data_section, class: :section do
    name { generate(:section_name) }
    schedule { 'MWF 2:00 PM' }
  end

  factory :section_in_closed_course, parent: :section do
    association :course, factory: :expired_course
  end

  factory :section_in_open_course, parent: :section do
    association :course, factory: :open_course
  end

  factory :section_in_archived_course, parent: :section do
    association :course, factory: :archived_course
  end

  factory :section_with_enrollments, parent: :section do
    transient do
      number_of_enrollments { 5 }
    end

    enrollments do
      Array.new(number_of_enrollments) { association(:enrollment) }
    end
  end

  factory :archived_section_in_archived_course, parent: :section_in_archived_course do |s|
    s.is_archived { true }
  end

  factory :enterprise_section, parent: :section do
    is_enterprise { true }
    association :course, factory: :enterprise_course
  end
end
