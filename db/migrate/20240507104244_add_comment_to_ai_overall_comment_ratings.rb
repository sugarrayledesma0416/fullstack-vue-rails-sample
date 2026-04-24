class AddCommentToAIOverallCommentRatings < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_overall_comment_ratings, :comment, :text
  end
end
