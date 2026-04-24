class AddRecordingIdToActivityNotes < ActiveRecord::Migration[4.2]
  def change
    add_column :activity_notes, :recording_id, :integer
  end
end
