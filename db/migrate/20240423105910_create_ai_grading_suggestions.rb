class CreateAIGradingSuggestions < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_grading_suggestions do |t|
      t.integer :prompt_id
      t.string :language_code, null: false
      t.integer :program_id, null: false
      t.integer :activity_id, null: false
      t.integer :attempt_id, null: false
      t.string :question_label, null: false
      t.text :suggestion_text, null: false
      t.integer :reviewed_by_id
      t.datetime :reviewed_at
      t.string :reviewed_status

      t.timestamps
    end
  end
end
