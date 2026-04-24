class DropRecordingAppInstance < ActiveRecord::Migration[4.2]
  def up
    drop_table :recording_app_instance
  end

  def down
    create_table :recording_app_instance do |t|
      t.integer  :client_count, null: false, default: 0

      t.timestamps
    end
  end
end
