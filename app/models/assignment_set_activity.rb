class AssignmentSetActivity < ApplicationRecord
  # TODO: Before shipping epic, we should determine if we need any compound indexes on
  # the two relationships for the use cases of our views
  belongs_to :assignment_set
  belongs_to :activity

  validates(
    :assignment_set_rank,
    presence: true,
    numericality: { greater_than: 0, only_integer: true }
  )

  validates(
    :activity_id,
    uniqueness: {
      message: 'already exists in this Assignment Set',
      scope: :assignment_set_id
    }
  )

  delegate :section, :due_date, to: :assignment_set

  def assignment
    section.assignments.find_by(assignable: activity, due_date: due_date)
  end
end
