class CreateAIChatFeedbackFlags < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_chat_feedback_flags do |t|
      t.string :comment
      t.string :message_guid
      t.integer :graded_by_id
      t.integer :program_id, null: false
      t.integer :activity_id, null: false

      t.references :ai_virtual_chat_session_messages,
                  null: false,
                  foreign_key: true,
                  index: { name: 'idx_feedback_flags_on_chat_message' }
      t.references :ai_suggestion_rating_categories,
                  null: false,
                  foreign_key: true,
                  index: { name: 'idx_feedback_flags_on_rating_category' }

      t.timestamps

    end

    add_index :ai_chat_feedback_flags,
              [:program_id, :activity_id, :message_guid],
              unique: true,
              name: 'ai_chat_feedback_flags_on_program_activity_message'
  end
end
