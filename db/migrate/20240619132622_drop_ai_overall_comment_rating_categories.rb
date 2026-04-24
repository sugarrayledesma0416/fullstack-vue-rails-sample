class DropAIOverallCommentRatingCategories < ActiveRecord::Migration[6.1]
  def change
    drop_table :ai_overall_comment_rating_categories
  end
end
