module AI
  class GradingSuggestionRating < ApplicationRecord
    self.table_name = 'ai_grading_suggestion_ratings'

    belongs_to :user
    belongs_to(
      :grading_suggestion,
      class_name: 'AI::GradingSuggestion',
      foreign_key: :grading_suggestion_id,
      inverse_of: :ratings
    )
    belongs_to(
      :rating_category,
      class_name: 'AI::SuggestionRatingCategory',
      foreign_key: :rating_category_id,
      inverse_of: :grading_suggestion_ratings
    )
  end
end
