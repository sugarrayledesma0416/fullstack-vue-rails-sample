class RemoveAIVirtualChatSessionActivitySectionAndUser < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      remove_column :ai_virtual_chat_sessions, :activity_id, :integer
      remove_column :ai_virtual_chat_sessions, :section_id, :integer
      remove_column :ai_virtual_chat_sessions, :user_id, :integer
    end
  end
end
