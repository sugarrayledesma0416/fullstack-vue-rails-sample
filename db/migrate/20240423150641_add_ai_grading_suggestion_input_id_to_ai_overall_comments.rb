class AddAIGradingSuggestionInputIdToAIOverallComments < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_overall_comments, :grading_suggestion_input_id, :integer

    add_index :ai_overall_comments, :grading_suggestion_input_id
  end
end
