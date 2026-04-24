class RemoveMessagesFromAIVirtualChatSessions < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_column :ai_virtual_chat_sessions, :messages, :text }
  end
end
