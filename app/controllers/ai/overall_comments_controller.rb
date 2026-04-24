module AI
  class OverallCommentsController < ApplicationController
    before_action :require_user

    def rate
      authorize! :rate, self.class

      rating_category = AI::SuggestionRatingCategory.find(params[:rating_category_id])
      comment = params[:comment]
      rating = AI::OverallCommentRating.find_or_create_by(
        user: current_user,
        overall_comment:
      ) do |record|
        record.rating_category = rating_category
        record.comment = comment
      end

      rating.update(rating_category:, comment:)

      if rating.valid?
        head :ok
      else
        render json: { errors: rating.errors.full_messages }, status: :bad_request
      end
    end

    private def overall_comment
      @overall_comment ||= OverallComment.find(params[:id])
    end
  end
end
