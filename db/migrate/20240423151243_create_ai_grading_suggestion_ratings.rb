class CreateAIGradingSuggestionRatings < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_grading_suggestion_ratings do |t|
      t.integer :user_id, null: false
      t.integer :grading_suggestion_id, null: false
      t.integer :rating_category_id, null: false

      t.timestamps
    end

    add_index(
      :ai_grading_suggestion_ratings,
      %i[user_id grading_suggestion_id],
      unique: true,
      name: 'ai_grading_suggestion_ratings_on_user_and_suggestion'
    )
    add_index(
      :ai_grading_suggestion_ratings,
      %i[grading_suggestion_id]
    )
  end
end
