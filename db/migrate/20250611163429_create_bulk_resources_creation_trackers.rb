class CreateBulkResourcesCreationTrackers < ActiveRecord::Migration[6.1]
  def change
    create_table :bulk_resources_creation_trackers do |t|
      t.string :zip_file_name
      t.string :csv_file_name
      t.string :state
      t.json :logs, default: {}, null: false
      t.integer :program_id, null: false

      t.timestamps
    end
  end
end
