class ProgramToProgramMapping < ApplicationRecord
  belongs_to :dest_program, class_name: 'Program'
  belongs_to :src_strand, class_name: 'Concept'
  # Destination strand can be nil if it has not yet been mapped
  # or if there is no corresponding strand in the destination program.
  belongs_to :dest_strand, class_name: 'Concept', optional: true

  validates_presence_of :dest_program_id, :src_strand_id
  validates :src_strand_id, uniqueness: { case_sensitive: true }

  def src_program_id
    src_strand.program_id
  end

  def self.source_program(destination_program)
    # Given a program, look for a mapping that has the program
    #   as the destination program. If there is one, find the program
    #   for its source strand.
    where(dest_program_id: destination_program.id).first&.src_strand&.program
  end
end
