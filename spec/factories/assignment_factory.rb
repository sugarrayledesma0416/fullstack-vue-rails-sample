FactoryBot.define do
  sequence :assignment_due_date do |n|
    # Ensures due dates are between today and the default end date
    # of the course defined by the course factory.
    # If n is greater than 179, the due dates start over from
    # tomorrow's date.
    valid_course_factory_days = ((6.months - 1.day) / 1.day)
    Date.today + (n % valid_course_factory_days)
  end

  factory :assignment do
    association :assignable, factory: :activity
    category
    current { false }
    due_date { generate(:assignment_due_date) }
    section
    individually_assignable { false }
  end

  factory :assignment_without_activity, class: :assignment do
    category
    current { false }
    due_date { generate(:assignment_due_date) }
  end

  factory :archived_assignment, parent: :assignment do
    is_archived { true }
  end
end
