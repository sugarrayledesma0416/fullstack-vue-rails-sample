class CreateAIChatOverallFeedbacks < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_chat_overall_feedbacks do |t|
      t.string :comment
      t.integer :graded_by_id
      t.integer :program_id, null: false
      t.integer :activity_id, null: false

      t.references :ai_virtual_chat_sessions,
                  null: false,
                  foreign_key: true,
                  index: { name: 'idx_overall_feedbacks_on_session' }
      t.timestamps
    end
  end
end
