class ProgramEdition < ApplicationRecord
  include Dangerfield::Publisher

  belongs_to :program
  belongs_to :next_edition_program, class_name: 'Program', optional: true
  belongs_to :previous_edition_program, class_name: 'Program', optional: true

  validate :program_exists
  validate :next_edition_program_exists, if: -> { next_edition_program_id.present? }
  validate :previous_edition_program_exists, if: -> { previous_edition_program_id.present? }

  private def program_exists
    errors.add(:program_id, 'there is no program with this id') unless Program.exists?(program_id)
  end

  private def next_edition_program_exists
    return if Program.exists?(next_edition_program_id)

    errors.add(:next_edition_program_id, 'there is no program with this next_edition_program_id')
  end

  private def previous_edition_program_exists
    return if Program.exists?(previous_edition_program_id)

    errors.add(:previous_edition_program_id,
               'there is no program with this previous_edition_program_id')
  end
end
