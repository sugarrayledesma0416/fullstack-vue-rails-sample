class CreateAISuggestionRatingDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_suggestion_rating_details do |t|
      t.integer :program_id, null: false
      t.integer :activity_id, null: false
      t.integer :attempt_id, null: false
      t.integer :updated_by_id
      t.string :question_label, null: false

      t.text :comment

      t.timestamps
    end

    add_index(
      :ai_suggestion_rating_details,
      %i[attempt_id question_label],
      unique: true,
      name: 'index_ai_suggestion_rating_details_on_attempt_and_question_label'
    )
  end
end
