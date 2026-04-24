class AddAttachmentIdIdxFeedbackItem < ActiveRecord::Migration[4.2]
  def change
    add_index :feedback_items, :attachment_id
  end
end
