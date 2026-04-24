class CreateCartridgeCartridgeBuildStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :cartridge_build_statuses do |t|
      t.string :cc_version
      t.string :status
      t.string :error_message
      t.string :file_name
      t.integer :creator_id
      t.integer :program_id

      t.timestamps
    end
  end
end
