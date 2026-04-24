class CreateAIVirtualChatSessionMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_virtual_chat_session_messages do |t|
      t.integer :session_id
      t.string :guid, null: false
      t.string :role
      t.text :message_text
      t.text :audio_file_path
      t.text :ai_api_response

      t.index(%i[session_id guid], unique: true)
    end
  end
end
