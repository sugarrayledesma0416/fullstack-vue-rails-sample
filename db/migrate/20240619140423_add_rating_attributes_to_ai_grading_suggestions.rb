class AddRatingAttributesToAIGradingSuggestions < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_grading_suggestions, :rating_category_id, :integer
    add_column :ai_grading_suggestions, :rating_comment, :string
    add_column :ai_grading_suggestions, :rated_by_id, :integer
    add_column :ai_grading_suggestions, :rated_at, :timestamp
  end
end
