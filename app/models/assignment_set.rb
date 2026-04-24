class AssignmentSet < ApplicationRecord
  belongs_to :section
  has_many(
    :activities,
    -> { order(assignment_set_rank: :asc) },
    class_name: 'AssignmentSetActivity',
    dependent: :destroy,
    inverse_of: :assignment_set
  )

  validates_presence_of :due_date, :section
  validate :unique_assignment_set_due_date_for_section
  validate :due_date_within_section_date_range

  accepts_nested_attributes_for :activities

  def due_date_within_section_date_range
    # Don't try to validate if due_date is blank
    return if errors[:due_date].present?

    return unless section && (due_date > section.course_end_date ||
                              due_date < section.course_start_date)

    errors.add(:due_date, 'must be within the section start and end dates.')
  end

  def unique_assignment_set_due_date_for_section
    # Don't try to validate if due_date is blank
    return if errors[:due_date].present?

    return unless section
    return unless section.assignment_set_due_dates.include?(due_date)

    errors.add(:due_date, 'already exists for this assignment set')
  end

  def manually_ordered?
    # Assuming this model is used for assignment due dates that are not manually ordered or
    # are not part of an assignment set in assignment set views
    persisted?
  end

  def self.dates_for_sections(section_ids)
    where(section_id: section_ids)
      .distinct
      .pluck(:due_date)
      .map do |due_date|
      due_date.strftime('%m/%d/%Y')
    end
  end
end
