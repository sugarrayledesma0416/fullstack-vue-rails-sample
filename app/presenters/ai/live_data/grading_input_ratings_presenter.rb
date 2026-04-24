module AI
  module LiveData
    class GradingInputRatingsPresenter
      include ::TocPresenterCommon
      # "Standard" means "not Supersite Junior"
      include ::StandardTocPresentation

      attr_reader(
        :current_program,
        :include_rated_inputs,
        :program,
        :rater
      )

      alias include_rated_inputs? include_rated_inputs

      def initialize(
        include_rated_inputs:,
        program:,
        req_params:,
        rater:
      )
        @include_rated_inputs = include_rated_inputs
        @program = program
        @req_params = req_params
        @rater = rater
      end

      def sections
        []
      end

      def display_lesson
        return @display_lesson if defined? @display_lesson

        @display_lesson = program.best_display_lesson(
          req_params[:display_lesson],
          req_params[:start_unit],
          units,
          trial_access?
        ).extend(LessonWithAIInputRatings)

        # Do not use tap to avoid infinite recursion.
        @display_lesson.toc_locations_with_grading_suggestion_inputs = \
          grading_suggestion_inputs.map do |input|
            input.activity.toc_location
          end

        @display_lesson
      end

      def current_strand
        @current_strand ||= toc_location || relevant_strand
      end

      def current_topic
        @current_topic ||= toc_location || relevant_topic
      end

      def notes_by_activity
        {}
      end

      # Return all the units to display in the units selector.
      # Check with PO if we need to filter out units with no grading suggestion
      # inputs to rate.
      def units
        program.browsable_units
      end

      def base_url(options = {})
        routes.ai_program_live_data_grading_input_ratings_path(
          base_url_params.merge(options)
        )
      end

      def base_url_params
        {
          program_id: program.id,
          include_rated_inputs:
        }
      end

      def show_hide_rated_inputs_url
        base_url(
          start_unit: req_params[:start_unit],
          display_lesson: req_params[:display_lesson],
          toc_location: req_params[:toc_location],
          include_rated_inputs: !include_rated_inputs
        )
      end

      def questions_for_activity(activity)
        # Return all the questions even if a question has nothing to rate.
        activity.content_object.questions.map do |question|
          {
            label: question.label,
            student_response_count: grading_suggestion_input_count_for_activity_and_question(
              activity:,
              question:
            ),
            grading_suggestion_count: grading_suggestion_count_for_activity_and_question(
              activity:,
              question:
            ),
            overall_comment_count: overall_comment_count_for_activity_and_question(
              activity:,
              question:
            )
          }.tap do |memo|
            if memo[:grading_suggestion_count].positive? || memo[:overall_comment_count].positive?
              memo[:rate_question_link] = rate_link_for_activity_and_question(
                activity:,
                question:
              )
            end
          end
        end
      end

      # Return the activities to display for the current lesson and strand.
      # Called by StandardTocPresentation.
      def activities
        @activities ||= grading_suggestion_inputs_by_activity.keys.select do |activity|
          activity.toc_location == current_strand.to_i
        end
      end

      private def rate_link_for_activity_and_question(activity:, question:)
        routes.ai_program_live_data_grading_input_rating_question_path(
          program_id: program.id,
          activity_id: activity.id,
          question_rank: question.rank,
          include_rated_inputs:
        )
      end

      private def grading_suggestion_input_count_for_activity_and_question(activity:, question:)
        (grading_suggestion_inputs_by_activity[activity] || []).count do |input|
          input.activity_id == activity.id && input.question_label == question.label
        end
      end

      private def grading_suggestion_count_for_activity_and_question(activity:, question:)
        grading_suggestions.count do |suggestion|
          suggestion.activity_id == activity.id && suggestion.question_label == question.label
        end
      end

      private def overall_comment_count_for_activity_and_question(activity:, question:)
        overall_comments.count do |comment|
          comment.activity_id == activity.id && comment.question_label == question.label
        end
      end

      private def grading_suggestion_inputs
        return @grading_suggestion_inputs if defined? @grading_suggestion_inputs

        join_query = AI::GradingSuggestionInput
          .where(
            activity: display_lesson.activities
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

      private def grading_suggestion_inputs_by_activity
        @grading_suggestion_inputs_by_activity ||= grading_suggestion_inputs.group_by(&:activity)
      end

      private def grading_suggestions
        return @grading_suggestions if defined? @grading_suggestions

        query = AI::GradingSuggestion.where(
          grading_suggestion_input: grading_suggestion_inputs.map(&:id)
        ).left_joins(:ratings)

        @grading_suggestions = if include_rated_inputs?
                                 query
                               else
                                 query
                                   .where(ratings: { id: nil })
                                   .or(query.where.not(ratings: { user_id: rater.id }))
                               end
      end

      private def overall_comments
        return @overall_comments if defined? @overall_comments

        query = AI::OverallComment.where(
          grading_suggestion_input: grading_suggestion_inputs.map(&:id)
        ).left_joins(:ratings)

        @overall_comments = if include_rated_inputs?
                              query
                            else
                              query
                                .where(ratings: { id: nil })
                                .or(query.where.not(ratings: { user_id: rater.id }))
                            end
      end

      private def toc_location
        display_lesson.extend(ParallelLocationFinding).parallel_toc_location(
          req_params[:toc_location]
        )
      end

      private def relevant_strand
        display_lesson.extend(ParallelLocationFinding).most_relevant_strand(
          req_params[:toc_location],
          saved_location
        )&.location&.to_s
      end

      private def relevant_topic
        display_lesson.extend(ParallelLocationFinding).most_relevant_topic(
          req_params[:toc_location],
          req_params[:start_strand],
          req_params[:start_topic],
          saved_location
        )
      end

      private def routes
        Rails.application.routes.url_helpers
      end

      module LessonWithAIInputRatings
        attr_accessor :toc_locations_with_grading_suggestion_inputs

        def strands
          toc_entries.select do |toc_entry|
            toc_locations_with_grading_suggestion_inputs.include?(toc_entry.location.to_i)
          end
        end
      end

    end
  end
end
