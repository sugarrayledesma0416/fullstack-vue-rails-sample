module AI
  class GradingSuggestionsController < ApplicationController
    before_action :require_user

    def rate
      authorize! :rate, self.class

      rating_category = AI::SuggestionRatingCategory.find(params[:rating_category_id])
      comment = params[:comment]
      rating = AI::GradingSuggestionRating.find_or_create_by(
        user: current_user,
        grading_suggestion:
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

    private def grading_suggestion
      @grading_suggestion ||= GradingSuggestion.find(params[:id])
    end
  end
end
