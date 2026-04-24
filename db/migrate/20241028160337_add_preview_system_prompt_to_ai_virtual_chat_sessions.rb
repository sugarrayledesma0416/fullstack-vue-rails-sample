class AddPreviewSystemPromptToAIVirtualChatSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_virtual_chat_sessions, :preview_system_prompt, :text
  end
end
