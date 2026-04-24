class AddAIGradingSuggestionInputIdToAIGradingSuggestions < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_grading_suggestions, :grading_suggestion_input_id, :integer

    add_index :ai_grading_suggestions, :grading_suggestion_input_id
  end
end
