class CreateAIVirtualChatSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_virtual_chat_sessions do |t|
      t.integer :activity_id
      t.integer :user_id
      t.text :messages
      t.text :model_config

      t.timestamps
    end
  end
end
