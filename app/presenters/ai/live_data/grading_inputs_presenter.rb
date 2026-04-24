module AI
  module LiveData
    class GradingInputsPresenter
      ACTIVITY_TYPES = [
        'open_ended',
        'composition'
      ].freeze

      OPTIONS_FOR_ACTIVITY_TYPE = [
        ['Open ended', 'open_ended'],
        ['Composition', 'composition']
      ].freeze

      MIN_SIZE_RESULT = 30

      attr_reader :program, :filter, :start_time, :end_time, :offset, :limit

      def initialize(
        program:,
        end_time:,
        filter:,
        start_time:,
        offset: nil,
        limit: nil
      )
        @program = program
        @filter = filter
        @start_time = start_time
        @end_time = end_time
        @offset = offset.present? ? offset.to_i : 0
        @limit = limit.present? ? limit.to_i : 100
      end

      def options_for_activity_type
        OPTIONS_FOR_ACTIVITY_TYPE
      end

      def form_url
        routes.ai_program_live_data_grading_inputs_path(
          program_id: program.id
        )
      end

      def load_more_url
        if limit == 0 || attempts.present?
          routes.ai_program_live_data_grading_inputs_path(
            program_id: program.id,
            start_date: start_time.to_formatted_s(:short),
            end_date: end_time.to_formatted_s(:short),
            activity_type: filter[:activity_type],
            offset: offset + attempts.count
          )
        end
      end

      def save_entry_url
        routes.ai_program_live_data_grading_inputs_path(
          program_id: program.id
        )
      end

      def entries
        attempts.flat_map do |attempt|
          activity = attempt.activity
          activity_extractor = activity_extractor_by_activity(activity)
          activity.content_object.questions.filter_map do |question|
            next unless attempt.results.has_response?(question.label)

            student_response = attempt.results.response(question.label)
            next if student_response.length < MIN_SIZE_RESULT

            # All the keys are camelCase because they'll be stored in a JSON
            # blob and used by JS code.
            {
              attemptId: attempt.id,
              activityTitle: activity.title,
              directionLine: activity_extractor.direction_line,
              questionLabel: question.label,
              questionPrompt: question.html_friendly_prompt,
              studentResponse: student_response,
              isSaved: AI::GradingSuggestionInput.exists?(
                attempt_id: attempt.id,
                question_label: question.label
              )
            }
          end
        end
      end

      private def activity_extractor_by_activity(activity)
        @activity_extractor_by_activity ||= {}

        @activity_extractor_by_activity[activity] ||= AI::ActivityExtractor.new(activity)
      end

      private def attempts
        @attempts ||= Attempt.where.not(
          section_id: 0
        ).where(
          status_code: AttemptStatus::CODE_COMPLETED,
          updated_at: start_time..end_time
        ).joins(
          :activity
        ).where(
          activities: { activity_type: activity_types }
        ).merge(
          Activity.by_program(program.id)
        ).order(
          updated_at: :asc
        ).offset(
          offset
        ).limit(
          limit
        )
      end

      private def activity_types
        filter[:activity_type].presence || ACTIVITY_TYPES
      end

      private def routes
        Rails.application.routes.url_helpers
      end
    end
  end
end
