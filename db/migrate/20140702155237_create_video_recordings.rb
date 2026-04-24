class CreateVideoRecordings < ActiveRecord::Migration[4.2]
  def up
    create_table :video_recordings do |vr|
      vr.string :recording_path
      vr.integer :user_id
      vr.string :uuid

      vr.timestamps
    end
  end

  def down
    drop_table :video_recordings
  end
end
