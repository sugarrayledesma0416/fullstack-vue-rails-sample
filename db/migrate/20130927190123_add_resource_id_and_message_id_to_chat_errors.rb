class AddResourceIdAndMessageIdToChatErrors < ActiveRecord::Migration[4.2]
  def self.up
    add_column :chat_errors, :message_id, :integer
    add_column :chat_errors, :resource_id, :string
  end

  def self.down
    remove_column :chat_errors, :message_id
    remove_column :chat_errors, :resource_id
  end
end
