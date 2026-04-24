module AI
  module LiveData
    class GradingInputRatingsQuestionPresenter
      attr_reader(
        :activity,
        :include_rated_inputs,
        :question_rank,
        :rater
      )

      alias include_rated_inputs? include_rated_inputs

      def initialize(activity:, include_rated_inputs:, question_rank:, rater:)
        @activity = activity
        @include_rated_inputs = include_rated_inputs
        @question_rank = question_rank
        @rater = rater
      end

      # Method required to display the activity link.
      def has_note?(activity)
        false
      end

      # Method required to display the activity link.
      def course
        nil
      end

      def lesson_url
        routes.ai_program_live_data_grading_input_ratings_path(
          display_lesson: activity.lesson_id,
          include_rated_inputs:,
          program_id: activity.program.id
        )
      end

      def strand_url
        routes.ai_program_live_data_grading_input_ratings_path(
          display_lesson: activity.lesson_id,
          include_rated_inputs:,
          program_id: activity.program.id,
          toc_location: activity.strand&.location
        )
      end

      def rate_grading_suggestion_url
        routes.ai_grading_suggestions_path
      end

      def rate_overall_comment_url
        routes.ai_overall_comments_path
      end

      def accept_overall_comment_rating_category
        @accept_overall_comment_rating_category ||= AI::SuggestionRatingCategory
          .internal
          .find_by!(label: 'Correct')
      end

      def reject_overall_comment_rating_category
        @reject_overall_comment_rating_category ||= AI::SuggestionRatingCategory
          .internal
          .find_by!(label: 'Incorrect')
      end

      def accept_grading_suggestion_rating_category
        @accept_grading_suggestion_rating_category ||= AI::SuggestionRatingCategory
          .internal
          .find_by!(label: 'Correct')
      end

      def reject_grading_suggestion_rating_category
        @reject_grading_suggestion_rating_category ||= AI::SuggestionRatingCategory
          .internal
          .find_by!(label: 'Incorrect')
      end

      def question
        @question ||= content_object.questions.detect do |question|
          question.rank == question_rank
        end
      end

      def serialized_grading_suggestion_inputs
        grading_suggestion_inputs.map do |input|
          {
            id: input.id,
            studentResponse: input.student_response,
            overallComments: serialized_overall_comments(input),
            gradingSuggestions: serialized_grading_suggestions(input)
          }
        end
      end

      private def serialized_grading_suggestions(input)
        (grading_suggestions_by_input_id[input.id] || []).map do |grading_suggestion|
          serialized_grading_suggestion(grading_suggestion)
        end
      end

      private def serialized_grading_suggestion(grading_suggestion)
        {
          id: grading_suggestion.id,
          incorrectText: grading_suggestion.incorrect_text,
          errorExplanation: grading_suggestion.error_explanation
        }.tap do |memo|
          ratings = grading_suggestion_ratings_by_grading_suggestion_id[grading_suggestion.id]
          rating = ratings&.detect { |rating| rating.user_id == rater.id }
          if rating
            memo[:rating] = {
              id: rating.id,
              ratingCategoryId: rating.rating_category_id,
              comment: rating.comment
            }
          end
        end
      end

      private def serialized_overall_comments(input)
        (overall_comments_by_input_id[input.id] || []).map do |overall_comment|
          serialized_overall_comment(overall_comment)
        end
      end

      private def serialized_overall_comment(overall_comment)
        {
          id: overall_comment.id,
          overallComment: overall_comment.overall_comment,
          explanation: overall_comment.explanation
        }.tap do |memo|
          ratings = overall_comment_ratings_by_overall_comment_id[overall_comment.id]
          rating = ratings&.detect { |rating| rating.user_id == rater.id }
          if rating
            memo[:rating] = {
              id: rating.id,
              ratingCategoryId: rating.rating_category_id,
              comment: rating.comment
            }
          end
        end
      end

      private def grading_suggestion_inputs
        return @grading_suggestion_inputs if defined? @grading_suggestion_inputs

        join_query = AI::GradingSuggestionInput
          .where(
            activity_id: activity.id,
            question_label: question.label
          ).joins(
            'left outer join ai_grading_suggestions gs ' \
            'on ai_grading_suggestion_inputs.id = gs.grading_suggestion_input_id'
          ).joins(
            'left outer join ai_overall_comments oc ' \
            'on ai_grading_suggestion_inputs.id = oc.grading_suggestion_input_id'
          ).joins(
            'left outer join ai_grading_suggestion_ratings gsr ' \
            'on gs.id = gsr.grading_suggestion_id'
          ).joins(
            'left outer join ai_overall_comment_ratings ocr ' \
            'on oc.id = ocr.overall_comment_id'
          )

        query = if include_rated_inputs?
                  join_query.where(
                    '(gs.id is not null) OR (oc.id is not null)'
                  )
                else
                  join_query.where(
                    "(gs.id is not null AND (gsr.id is null OR gsr.user_id <> #{rater.id})) OR " \
                    "(oc.id is not null AND (ocr.id is null OR ocr.user_id <> #{rater.id}))"
                  )
                end

        @grading_suggestion_inputs = query
          .distinct
          .includes(:activity)
      end

      private def grading_suggestions
        return @grading_suggestions if defined? @grading_suggestions

        query = AI::GradingSuggestion.where(
          grading_suggestion_input_id: grading_suggestion_inputs.map(&:id)
        ).left_joins(:ratings).distinct

        @grading_suggestions = if include_rated_inputs?
                                 query
                               else
                                 query
                                   .where(ratings: { id: nil })
                                   .or(query.where.not(ratings: { user_id: rater.id }))
                               end
      end

      private def grading_suggestions_by_input_id
        @grading_suggestions_by_input_id ||= grading_suggestions.group_by(
          &:grading_suggestion_input_id
        )
      end

      private def grading_suggestion_ratings_by_grading_suggestion_id
        @grading_suggestion_ratings_by_grading_suggestion_id ||= AI::GradingSuggestionRating.where(
          grading_suggestion_id: grading_suggestions.map(&:id)
        ).group_by(&:grading_suggestion_id)
      end

      private def overall_comments
        return @overall_comments if defined? @overall_comments

        query = AI::OverallComment.where(
          grading_suggestion_input_id: grading_suggestion_inputs.map(&:id)
        ).left_joins(:ratings).distinct

        @overall_comments = if include_rated_inputs?
                              query
                            else
                              query
                                .where(ratings: { id: nil })
                                .or(query.where.not(ratings: { user_id: rater.id }))
                            end
      end

      private def overall_comments_by_input_id
        @overall_comments_by_input_id ||= overall_comments.group_by(
          &:grading_suggestion_input_id
        )
      end

      private def overall_comment_ratings_by_overall_comment_id
        @overall_comment_ratings_by_overall_comment_id ||= AI::OverallCommentRating.where(
          overall_comment_id: overall_comments.map(&:id)
        ).group_by(&:overall_comment_id)
      end

      private def content_object
        activity.content_object
      end

      private def routes
        Rails.application.routes.url_helpers
      end
    end
  end
end
