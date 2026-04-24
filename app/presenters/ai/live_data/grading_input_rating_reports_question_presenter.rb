module AI
  module LiveData
    class GradingInputRatingReportsQuestionPresenter
      OverallCommentStats = Struct.new(
        :overall_comment,
        :explanation,
        :accepted_count,
        :rejected_count,
        :rater_comments,
        keyword_init: true
      )
      GradingSuggestionStats = Struct.new(
        :incorrect_text,
        :explanation,
        :accepted_count,
        :rejected_count,
        :rater_comments,
        keyword_init: true
      )

      attr_reader(
        :activity,
        :question_rank
      )

      def initialize(activity:, question_rank:)
        @activity = activity
        @question_rank = question_rank
      end

      def lesson_url
        routes.instructor_toc_path(
          program.id,
          display_lesson: activity.lesson
        )
      end

      def strand_url
        routes.instructor_toc_path(
          program.id,
          display_lesson: activity.lesson,
          toc_location: activity.strand.location
        )
      end

      def question
        @question ||= content_object.questions.detect do |question|
          question.rank == question_rank
        end
      end

      def inputs
        @inputs ||= AI::GradingSuggestionInput.where(
          id: overall_comments_by_input_id.keys + grading_suggestions_by_input_id.keys
        )
      end

      def overall_comments_stats_for_input(input)
        @overall_comments_stats_by_input ||= {}

        @overall_comments_stats_by_input[input.id] ||=
          (overall_comments_by_input_id[input.id] || []).map do |overall_comment|
            OverallCommentStats.new(
              overall_comment: overall_comment.overall_comment,
              explanation: overall_comment.explanation,
              accepted_count: overall_comment.ratings.where(
                rating_category_id: accepted_rating_category.id
              ).count,
              rejected_count: overall_comment.ratings.count do |rating|
                rating.rating_category_id == rejected_rating_category.id
              end,
              rater_comments: overall_comment.ratings.filter_map do |rating|
                if rating.rating_category_id == rejected_rating_category.id
                  rating.comment
                end
              end.compact_blank
            )
          end
      end

      def grading_suggestions_stats_for_input(input)
        @grading_suggestions_stats_by_input ||= {}

        @grading_suggestions_stats_by_input[input.id] ||=
          (grading_suggestions_by_input_id[input.id] || []).map do |grading_suggestion|
            GradingSuggestionStats.new(
              incorrect_text: grading_suggestion.incorrect_text,
              explanation: grading_suggestion.error_explanation,
              accepted_count: grading_suggestion.ratings.where(
                rating_category_id: accepted_rating_category.id
              ).count,
              rejected_count: grading_suggestion.ratings.count do |rating|
                rating.rating_category_id == rejected_rating_category.id
              end,
              rater_comments: grading_suggestion.ratings.filter_map do |rating|
                if rating.rating_category_id == rejected_rating_category.id
                  rating.comment
                end
              end.compact_blank
            )
          end
      end

      private def overall_comments_by_input_id
        @overall_comments_by_input_id ||= overall_comments.group_by(&:grading_suggestion_input_id)
      end

      private def overall_comments
        @overall_comments ||= AI::OverallComment.internal.where(
          activity_id: activity.id,
          question_label: question.label
        ).joins(
          :ratings
        ).where(
          ratings: { rating_category_id: rejected_rating_category.id }
        ).includes(:ratings)
      end

      private def grading_suggestions_by_input_id
        @grading_suggestions_by_input_id ||= grading_suggestions.group_by(&:grading_suggestion_input_id)
      end

      private def grading_suggestions
        @grading_suggestions ||= AI::GradingSuggestion.internal.where(
          activity_id: activity.id,
          question_label: question.label
        ).joins(
          :ratings
        ).where(
          ratings: { rating_category_id: rejected_rating_category.id }
        ).includes(:ratings)
      end

      private def accepted_rating_category
        @accepted_rating_category ||= AI::SuggestionRatingCategory
          .internal
          .find_by!(label: 'Correct')
      end

      private def rejected_rating_category
        @rejected_rating_category ||= AI::SuggestionRatingCategory
          .internal
          .find_by!(label: 'Incorrect')
      end

      private def content_object
        activity.content_object
      end

      private def program
        @program ||= activity.program
      end

      private def routes
        Rails.application.routes.url_helpers
      end
    end
  end
end
