class AddRecordingIdToFeedbackItems < ActiveRecord::Migration[4.2]
  def self.up
    add_column :feedback_items, :recording_id, :integer, :null => true
  end

  def self.down
    remove_column :feedback_items, :recording_id
  end
end
