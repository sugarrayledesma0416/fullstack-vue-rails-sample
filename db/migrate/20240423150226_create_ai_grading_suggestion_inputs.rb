class CreateAIGradingSuggestionInputs < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_grading_suggestion_inputs do |t|
      t.integer :program_id, null: false
      t.integer :activity_id, null: false
      t.integer :attempt_id, null: false
      t.string :question_label, null: false
      t.text :student_response, null: false

      t.index(
        %i[attempt_id question_label],
        name: 'index_ai_grading_suggestion_inputs_on_attempt_question_label'
      )
      t.index(
        %i[activity_id question_label],
        name: 'index_ai_grading_suggestion_inputs_on_activity_question_label'
      )
      t.index %i[program_id]

      t.timestamps
    end
  end
end
