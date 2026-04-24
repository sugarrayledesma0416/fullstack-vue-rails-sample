class CreateProgramConfigs < ActiveRecord::Migration[4.2]
  def change
    create_table :program_configs do |t|
      t.integer :program_id, null: false
      t.text :datastore_json, null: false
      t.integer :creator_id, null: false

      t.timestamps
    end

    add_index :program_configs, :program_id
  end
end
