class AddCommentToAIGradingSuggestionRatings < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_grading_suggestion_ratings, :comment, :text
  end
end
