module AI
  class OverallCommentRating < ApplicationRecord
    self.table_name = 'ai_overall_comment_ratings'

    belongs_to :user
    belongs_to(
      :overall_comment,
      class_name: 'AI::OverallComment',
      foreign_key: :overall_comment_id,
      inverse_of: :ratings
    )
    belongs_to(
      :rating_category,
      class_name: 'AI::SuggestionRatingCategory',
      foreign_key: :rating_category_id,
      inverse_of: :overall_comment_ratings
    )
  end
end
