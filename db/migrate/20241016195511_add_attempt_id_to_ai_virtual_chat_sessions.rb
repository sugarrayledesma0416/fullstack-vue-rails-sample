class AddAttemptIdToAIVirtualChatSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_virtual_chat_sessions, :attempt_id, :bigint
    add_index :ai_virtual_chat_sessions, :attempt_id
  end
end
