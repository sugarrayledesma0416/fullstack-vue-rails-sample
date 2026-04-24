class CreateAdditionalNonInternalAISuggestionRatingCategories < ActiveRecord::Migration[6.1]
  RATING_CATEGORY_LABELS = [
    'Detected Nonexistent Error',
    'Identified Error Incorrectly',
    'Confusing Message Wording',
    'Error Not Worth Calling Out'
  ].freeze

  def up
    RATING_CATEGORY_LABELS.each do |label|
      AI::SuggestionRatingCategory.create!(
        description: '',
        internal_use: false,
        label:
      )
    end
  end

  def down
    AI::SuggestionRatingCategory.where(
      internal_use: false,
      label: RATING_CATEGORY_LABELS
    ).destroy_all
  end
end

