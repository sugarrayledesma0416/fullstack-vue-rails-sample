class RenameDefaultNonInternalAISuggestionRatingCategories < ActiveRecord::Migration[6.1]
  def up
    category = AI::SuggestionRatingCategory.non_internal.find_by(label: 'Unspecified')
    category&.update!(label: 'other')
  end

  def down
    category = AI::SuggestionRatingCategory.non_internal.find_by(label: 'other')
    category&.update!(label: 'Unspecified')
  end
end
