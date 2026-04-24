class CreateProgramToProgramMappings < ActiveRecord::Migration[4.2]
  def change
    create_table :program_to_program_mappings do |t|
      t.references :dest_program
      t.references :src_strand
      t.references :dest_strand
      t.timestamps
    end
  end
end
