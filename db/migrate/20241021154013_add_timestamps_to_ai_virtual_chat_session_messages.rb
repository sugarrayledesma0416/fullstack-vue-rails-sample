class AddTimestampsToAIVirtualChatSessionMessages < ActiveRecord::Migration[6.1]
  def change
    add_timestamps(:ai_virtual_chat_session_messages, null: true)
  end
end
