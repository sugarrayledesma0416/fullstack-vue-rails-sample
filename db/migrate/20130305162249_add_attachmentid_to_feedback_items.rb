class AddAttachmentidToFeedbackItems < ActiveRecord::Migration[4.2]
  def self.up
    add_column :feedback_items, :attachment_id, :integer
  end

  def self.down
    remove_column :feedback_items, :attachment_id
  end
end
