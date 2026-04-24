class CreateAIOverallCommentRatings < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_overall_comment_ratings do |t|
      t.integer :user_id, null: false
      t.integer :overall_comment_id, null: false
      t.integer :rating_category_id, null: false

      t.timestamps
    end

    add_index(
      :ai_overall_comment_ratings,
      %i[user_id overall_comment_id],
      unique: true,
      name: 'ai_overall_comment_ratings_on_user_and_overall_comment'
    )
    add_index(
      :ai_overall_comment_ratings,
      %i[overall_comment_id]
    )
  end
end
