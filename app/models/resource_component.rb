class ResourceComponent < ApplicationRecord
  has_many :resources
  belongs_to :program

  scope :components_by_program, (
    lambda do |program|
      select('resource_components.*')
        .joins(:resources)
        .where(program_id: program)
        .group('resource_components.id')
    end
  )

  scope :by_program, ->(program) { where(program_id: program) }

  def <=>(other)
    if self.name == 'Other'
      -1
    elsif other.name == 'Other'
      1
    else
      self.name <=> other.name
    end
  end
end
