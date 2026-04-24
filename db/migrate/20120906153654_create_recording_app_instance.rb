class CreateRecordingAppInstance < ActiveRecord::Migration[4.2]
  def self.up
    create_table :recording_app_instance do |t|
      t.integer  :client_count, :null => false, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :recording_app_instance
  end
end
