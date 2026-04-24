class CreateAIGradingSuggestionJobs < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_grading_suggestion_jobs do |t|
      t.bigint :attempt_id, null: false
      t.string :question_label, null: false
      t.string :status, null: false

      t.timestamps

      t.index %i[attempt_id question_label], name: 'index_on_attempt_and_question_label'
    end
  end
end
