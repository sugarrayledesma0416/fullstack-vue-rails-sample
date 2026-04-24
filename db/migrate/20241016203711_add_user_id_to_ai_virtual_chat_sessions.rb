class AddUserIdToAIVirtualChatSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_virtual_chat_sessions, :user_id, :integer
    add_index :ai_virtual_chat_sessions, :user_id
  end
end
