class TrackGroup < ApplicationRecord
  belongs_to :program
  belongs_to :lesson
  belongs_to :concept
  belongs_to :group_set, optional: true

  has_many :assignments

  scope :by_program, ->(program) { where(program_id: program) }

  def self.names_by_program(program)
    by_program(program).pluck(:name).uniq
  end
end
