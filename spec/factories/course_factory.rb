FactoryBot.define do
  sequence :course_number do | n |
    names = ['101', '102', '103', '120', '121']
    names[n % names.length]
  end

  factory :course do
    sequence(:name) { |n| "course #{n}" }
    level { 'factory course level' }
    program
    school
    association :owner, factory: :instructor
    association :creator, factory: :user
    start_date { 1.months.ago.to_date }
    end_date { 6.months.from_now.to_date }
    is_enterprise { false }
    first_unit do
      if program&.units&.present?
        program.units.first
      elsif program
        association(:unit, rank: 1, program: program)
      end
    end
    last_unit do
      if program&.units&.present?
        program.units.last
      elsif program
        association(:unit, rank: 2, program: program)
      end
    end
    sequence(:guid) { |_n| SecureRandom.uuid }
    after(:create) { |c| c.updated_by = c.owner_id }
  end

  factory :draft_course, parent: :course do
    draft { true }
  end

  factory :open_course, parent: :course do
    end_date { 6.months.from_now.to_date }
  end

  factory :editable_course, parent: :course do
    end_date { 1.month.ago.to_date }
    start_date { 2.months.ago.to_date }
    allow_past_end_date { true }
  end

  factory :closed_course, parent: :course do
    start_date { 1.year.ago.to_date }
    end_date { 2.months.ago.to_date }
    allow_past_end_date { true }
  end

  factory :archived_course, parent: :course do
    is_archived { true }
  end

  factory :course_with_instructor, parent: :course do
    association :owner, factory: :instructor
    level { 'Intro' }
  end

  factory :rep_course, parent: :course do
    sequence(:name) {|n| "Sample #{n}" }
    level { 'factory course level' }
    program
    school
    start_date { 1.month.ago.to_date }
    end_date { 72.months.from_now.to_date }
  end

  factory :expired_course, parent: :course do
    start_date { 12.months.ago.to_date }
    end_date { 6.months.ago.to_date }
    allow_past_end_date { true }
  end

  factory :course_with_section, parent: :course do
    sections do
      [
        association(:section, course: instance)
      ]
    end
  end

  factory :course_with_sections, parent: :course do
    sections do
      [
        association(:section, course: instance),
        association(:section, course: instance)
      ]
    end
  end

  factory :example_data_course, parent: :course do
    level { 'Intro' }
  end

  factory :expired_course_with_instructor, parent: :course do
    association :owner, factory: :instructor
    level { 'Intro' }
    start_date { 12.months.ago.to_date }
    end_date { 6.months.ago.to_date }
    allow_past_end_date { true }
  end

  factory :course_template, parent: :course do
    is_template { true }
  end

  factory :course_template_with_section, parent: :course_with_section do
    is_template { true }
  end

  factory :enterprise_course, parent: :course do
    is_enterprise { true }
  end
end
