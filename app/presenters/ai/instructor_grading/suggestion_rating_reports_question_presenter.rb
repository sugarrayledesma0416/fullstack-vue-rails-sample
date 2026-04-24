module AI
  module InstructorGrading
    class SuggestionRatingReportsQuestionPresenter
      attr_reader(
        :activity,
        :attempt,
        :grading_suggestion_prompt,
        :limit,
        :offset,
        :overall_comment_prompt,
        :question_rank
      )

      def initialize(
        activity:,
        grading_suggestion_prompt:,
        overall_comment_prompt:,
        question_rank:,
        limit: nil,
        offset: nil,
        attempt: nil
      )
        @activity = activity
        @grading_suggestion_prompt = grading_suggestion_prompt
        @overall_comment_prompt = overall_comment_prompt
        @question_rank = question_rank
        @limit = limit.present? ? limit.to_i : 2
        @offset = offset.present? ? offset.to_i : 0
        @attempt = attempt
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

      # Return the url to load the next batch of entries if:
      # - We are not loading a specific attempt
      # - And there are more attempts to load.
      def load_more_url
        if attempt.blank? && (limit.zero? || attempts.present?)
          routes.ai_program_instructor_grading_suggestion_rating_reports_question_path(
            program_id: program.id,
            activity_id: activity.id,
            question_rank: question.rank,
            offset: offset + entries.count,
            grading_suggestion_prompt_id: grading_suggestion_prompt&.id,
            overall_comment_prompt_id: overall_comment_prompt&.id
          )
        end
      end

      def question
        @question ||= content_object.questions.detect do |question|
          question.rank == question_rank
        end
      end

      def rating_categories
        AI::SuggestionRatingCategory.non_internal.map do |category|
          {
            id: category.id,
            label: category.label
          }
        end
      end

      def grading_suggestion_prompts
        AI::GradingSuggestionPrompt.all.map do |prompt|
          {
            id: prompt.id,
            label: "#{prompt.model}#{' (*)' if prompt.active_for_instructor_grading?}",
            model: prompt.model,
            url: routes.edit_ai_grading_prompt_path(id: prompt.id)
          }
        end
      end

      def overall_comment_prompts
        AI::OverallCommentPrompt.all.map do |prompt|
          {
            id: prompt.id,
            label: "#{prompt.model}#{' (*)' if prompt.active_for_instructor_grading?}",
            model: prompt.model,
            url: routes.edit_ai_grading_prompt_path(id: prompt.id, prompt_type: 'overall')
          }
        end
      end

      def options
        {
          showGradingSuggestionPrompt: grading_suggestion_prompt.blank?,
          showOverallCommentPrompt: overall_comment_prompt.blank?,
          showPagination: attempt.blank?
        }
      end

      def entries
        return [] if limit.zero?

        @entries ||= attempts.map do |attempt|
          {
            attemptId: attempt.id,
            studentResponse: attempt.results.response(question.label),
            gradingSuggestions: grading_suggestions_for_attempt_and_question(
              attempt:,
              question:
            ).map do |grading_suggestion|
              serialized_grading_suggestion(grading_suggestion)
            end,
            overallComments: overall_comments_for_attempt_and_question(
              attempt:,
              question:
            ).map do |overall_comment|
              serialized_overall_comments(overall_comment)
            end
          }
        end
      end

      private def serialized_grading_suggestion(grading_suggestion)
        {
          id: grading_suggestion.id,
          incorrectText: grading_suggestion.incorrect_text,
          errorExplanation: grading_suggestion.error_explanation,
          promptId: grading_suggestion.prompt_id,
          ratingCategoryId: grading_suggestion.rating_category_id,
          ratingComment: grading_suggestion.rating_comment
        }
      end

      private def serialized_overall_comments(overall_comment)
        {
          id: overall_comment.id,
          overallComment: overall_comment.overall_comment,
          explanation: overall_comment.explanation,
          promptId: overall_comment.prompt_id,
          ratingCategoryId: overall_comment.rating_category_id,
          ratingComment: overall_comment.rating_comment
        }
      end

      private def attempts
        @attempts = if attempt.present?
                      [attempt]
                    else
                      find_attempts
                    end
      end

      private def find_attempts
        join_query = Attempt.where(
          activity_id: activity.id
        ).left_outer_joins(
          :ai_grading_suggestions
        ).left_outer_joins(
          :ai_overall_comments
        )

        grading_suggestion_where_clause = {
          question_label: question.label
        }.tap do |memo|
          if grading_suggestion_prompt.present?
            memo[:prompt_id] = grading_suggestion_prompt.id
          end
        end
        overall_comment_where_clause = {
          question_label: question.label
        }.tap do |memo|
          if overall_comment_prompt.present?
            memo[:prompt_id] = overall_comment_prompt.id
          end
        end

        join_query.where(
          ai_grading_suggestions: grading_suggestion_where_clause
        ).where.not(
          ai_grading_suggestions: { rated_by_id: nil }
        ).or(
          join_query.where(
            ai_overall_comments: overall_comment_where_clause
          ).where.not(
            ai_overall_comments: { rated_by_id: nil }
          )
        ).distinct.offset(offset).limit(limit)
      end

      private def grading_suggestions_for_attempt_and_question(attempt:, question:)
        query = AI::GradingSuggestion.non_internal.where(
          attempt_id: attempt.id,
          question_label: question.label
        ).where.not(
          rated_by: nil
        )

        if grading_suggestion_prompt.present?
          query = query.where(prompt_id: grading_suggestion_prompt.id)
        end

        query
      end

      private def overall_comments_for_attempt_and_question(attempt:, question:)
        query = AI::OverallComment.non_internal.where(
          attempt_id: attempt.id,
          question_label: question.label
        ).where.not(
          rated_by: nil
        )

        if overall_comment_prompt.present?
          query = query.where(prompt_id: overall_comment_prompt.id)
        end

        query
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
