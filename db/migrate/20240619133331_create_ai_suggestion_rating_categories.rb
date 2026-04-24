class CreateAISuggestionRatingCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_suggestion_rating_categories do |t|
      t.boolean :internal_use, :boolean, default: false, null: false
      t.text :label
      t.string :description

      t.timestamps
    end
  end
end
