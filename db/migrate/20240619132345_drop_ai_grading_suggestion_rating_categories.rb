class DropAIGradingSuggestionRatingCategories < ActiveRecord::Migration[6.1]
  def change
    drop_table :ai_grading_suggestion_rating_categories
  end
end
