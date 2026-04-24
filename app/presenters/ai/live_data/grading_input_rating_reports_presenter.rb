module AI
  module LiveData
    class GradingInputRatingReportsPresenter
      attr_reader :program

      def initialize(program:)
        @program = program
      end

      def entries
        inputs.map do |input|
          activity = input.activity
          lesson = activity.lesson
          {
            activity:,
            lesson_path: routes.instructor_toc_path(
              program.id,
              display_lesson: lesson,
              toc_location: activity.strand.location
            ),
            question_label: input.question_label,
            details_path: routes.ai_program_live_data_grading_input_rating_reports_question_path(
              program.id,
              activity_id: activity.id,
              question_rank: question_rank_for_input(input),
              anchor: "input-#{input.id}"
            ),
            student_response: input.student_response
          }.tap do |memo|
            memo[:explanations] = explanations_for_input(input)
          end
        end
      end

      private def question_rank_for_input(input)
        @question_rank_for_input ||= {}

        @question_rank_for_input[input] ||= input.activity.content_object.questions.detect do |question|
          question.label == input.question_label
        end.rank
      end

      private def explanations_for_input(input)
        overall_comments = overall_comments_by_input_id[input.id] || []
        overall_comment_explanations = overall_comments.map do |overall_comment|
          "#{overall_comment.overall_comment}. #{overall_comment.explanation}"
        end
        grading_suggestions = grading_suggestions_by_input_id[input.id] || []
        grading_suggestion_explanations = grading_suggestions.map(&:error_explanation)

        overall_comment_explanations + grading_suggestion_explanations
      end

      private def inputs
        @inputs ||= AI::GradingSuggestionInput.where(
          id: overall_comments_by_input_id.keys + grading_suggestions_by_input_id.keys
        ).includes(:activity)
      end

      private def overall_comments_by_input_id
        @overall_comments_by_input_id ||= overall_comments.group_by(&:grading_suggestion_input_id)
      end

      private def overall_comments
        @overall_comments ||= AI::OverallComment.internal.joins(
          :ratings
        ).where(
          ratings: { rating_category_id: rejected_rating_category.id }
        ).includes(:ratings)
      end

      private def grading_suggestions_by_input_id
        @grading_suggestions_by_input_id ||= grading_suggestions.group_by(&:grading_suggestion_input_id)
      end

      private def grading_suggestions
        @grading_suggestions ||= AI::GradingSuggestion.internal.joins(
          :ratings
        ).where(
          ratings: { rating_category_id: rejected_rating_category.id }
        ).includes(:ratings)
      end

      private def overall_comment_rater_count
        @rater_count ||= AI::OverallCommentRating.where(
          overall_comment_id: overall_comments.map(&:id)
        ).count('DISTINCT user_id')
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

      private def routes
        Rails.application.routes.url_helpers
      end
    end
  end
end
