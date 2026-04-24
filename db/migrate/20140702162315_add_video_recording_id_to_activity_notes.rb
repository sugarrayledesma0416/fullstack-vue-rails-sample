class AddVideoRecordingIdToActivityNotes < ActiveRecord::Migration[4.2]
  def up
    add_column :activity_notes, :video_recording_id, :integer
  end

  def down
    drop_column :activity_notes, :video_recording_id
  end
end
