class AddRatingAttributesToAIOverallComments < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_overall_comments, :rating_category_id, :integer
    add_column :ai_overall_comments, :rating_comment, :string
    add_column :ai_overall_comments, :rated_by_id, :integer
    add_column :ai_overall_comments, :rated_at, :timestamp
  end
end
