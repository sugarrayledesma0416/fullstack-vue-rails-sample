class CreateIgcCopyJobs < ActiveRecord::Migration[4.2]
  def change
    create_table :igc_copy_jobs do |t|
      t.references :instructor
      t.references :src_program
      t.references :dest_program
      t.timestamps
    end
  end
end

