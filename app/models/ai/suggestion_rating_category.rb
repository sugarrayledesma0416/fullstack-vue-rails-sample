module AI
  class SuggestionRatingCategory < ApplicationRecord
    self.table_name = 'ai_suggestion_rating_categories'

    has_many(
      :overall_comment_ratings,
      class_name: 'AI::OverallCommentRating',
      dependent: :destroy,
      inverse_of: :rating_category,
      foreign_key: :rating_category_id
    )
    has_many(
      :overall_comments,
      class_name: 'AI::OverallComment',
      dependent: :nullify,
      inverse_of: :rating_category,
      foreign_key: :rating_category_id
    )
    has_many(
      :grading_suggestion_ratings,
      class_name: 'AI::GradingSuggestionRating',
      dependent: :destroy,
      inverse_of: :rating_category,
      foreign_key: :rating_category_id
    )
    has_many(
      :grading_suggestions,
      class_name: 'AI::GradingSuggestion',
      dependent: :nullify,
      inverse_of: :rating_category,
      foreign_key: :rating_category_id
    )

    validates(:label, presence: true)

    scope :non_internal, -> { where(internal_use: false) }
    scope :internal, -> { where(internal_use: true) }
  end
end
