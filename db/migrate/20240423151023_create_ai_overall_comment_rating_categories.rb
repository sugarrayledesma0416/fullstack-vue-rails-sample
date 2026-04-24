class CreateAIOverallCommentRatingCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_overall_comment_rating_categories do |t|
      t.text :label
      t.string :description

      t.timestamps
    end
  end
end
