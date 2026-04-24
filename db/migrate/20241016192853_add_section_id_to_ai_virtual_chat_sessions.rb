class AddSectionIdToAIVirtualChatSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_virtual_chat_sessions, :section_id, :integer
  end
end
