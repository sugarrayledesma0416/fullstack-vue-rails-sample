class AddGradingSuggestionJobIdToAIGradingSuggestions < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_grading_suggestions, :ai_grading_suggestion_job_id, :bigint

    add_index :ai_grading_suggestions, :ai_grading_suggestion_job_id
  end
end
