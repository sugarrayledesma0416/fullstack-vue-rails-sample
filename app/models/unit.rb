class Unit < ApplicationRecord
  include CurrentEventsContent

  belongs_to :program
  has_many :lessons, -> { order('lessons.rank ASC') }
  belongs_to :media_item, optional: true
  has_many :resources

  scope :released, -> { where( { released: true } ) }
  scope :by_program, ->(program) { where({ program_id: program } ) }
  scope :resource_only, -> { where({ use_type: 'ResourceUnit' } ) }
  scope :in_rank_range, ->(start_rank, end_rank) {
                                          where( ['units.rank >= ?
                                                  AND units.rank <= ?',
                                                 start_rank, end_rank]
                                          ).order('units.rank ASC')
                                      }
  scope :by_activity, ->(activity) { joins(lessons: :activities).where(activities: { id: activity }) }

  def display_name
    return name if !label || label.blank?
    label
  end

  def resources_form_display_name
    if resources_form_title.present?
      resources_form_title
    else
      display_name
    end
  end

  def self.resource_only_unit_for_program(program)
    Unit.by_program(program).resource_only.first
  end
end
