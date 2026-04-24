class CreateDefaultAISuggestionRatingCategories < ActiveRecord::Migration[6.1]
  RATING_CATEGORY_LABELS = %w[Correct Incorrect].freeze

  def up
    RATING_CATEGORY_LABELS.each do |label|
      AI::SuggestionRatingCategory.create!(
        description: '',
        internal_use: true,
        label:
      )
    end
  end

  def down
    AI::SuggestionRatingCategory.where(
      internal_use: true,
      label: RATING_CATEGORY_LABELS
    ).destroy_all
  end
end
