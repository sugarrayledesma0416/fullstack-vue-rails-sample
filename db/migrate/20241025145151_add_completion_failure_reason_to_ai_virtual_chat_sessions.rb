class AddCompletionFailureReasonToAIVirtualChatSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_virtual_chat_sessions, :completion_failure_reason, :text
  end
end
