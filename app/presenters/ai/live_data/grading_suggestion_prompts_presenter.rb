module AI
  module LiveData
    class GradingSuggestionPromptsPresenter
      class ActivityData
        attr_reader :activity, :program, :questions

        delegate :title, :direction_line, to: :activity

        def initialize(activity:, program:, questions:)
          @activity = activity
          @program = program
          @questions = questions
        end

        def lesson_url
          routes.instructor_toc_path(
            activity.program.id,
            display_lesson: activity.lesson
          )
        end

        def lesson_name
          activity.lesson.name
        end

        def strand_url
          routes.instructor_toc_path(
            program.id,
            display_lesson: activity.lesson,
            toc_location: activity.strand.location
          )
        end

        def strand_label
          activity.lesson_strand_label
        end

        def activity_url
          routes.section_activity_path(id: activity.id, section_id: 0)
        end

        private def routes
          Rails.application.routes.url_helpers
        end
      end

      QuestionData = Struct.new(
        :rank,
        :html_friendly_prompt,
        :inputs,
        keyword_init: true
      )

      InputData = Struct.new(
        :student_response,
        :suggestions_by_prompt,
        keyword_init: true
      )

      attr_reader :program, :comparison_prompt_ids

      def initialize(program:, comparison_prompt_ids:)
        @program = program
        @comparison_prompt_ids = if comparison_prompt_ids.present?
                                   comparison_prompt_ids.select(&:present?)[0..2]
                                 else
                                   []
                                 end

        GradingSuggestionPrompt.current
      end

      def comparable_prompts
        @comparable_prompts ||= AI::GradingSuggestionPrompt.order(id: :desc)
      end

      def comparison_prompts
        @comparison_prompts ||= if comparison_prompt_ids.present?
                                  AI::GradingSuggestionPrompt.find(comparison_prompt_ids)
                                else
                                  []
                                end
      end

      def activities
        @activities ||= inputs_by_activity.keys.map do |activity|
          ActivityData.new(
            activity:,
            program:,
            questions: questions_data_for_activity(activity)
          )
        end
      end

      private def questions_data_for_activity(activity)
        activity.questions.filter_map do |question|
          inputs = inputs_for_activity_and_question(activity:, question:)
          next if inputs.blank?

          QuestionData.new(
            rank: question.rank,
            html_friendly_prompt: question.html_friendly_prompt,
            inputs: inputs.map do |input|
              InputData.new(
                student_response: input.student_response,
                suggestions_by_prompt: comparison_prompts.index_with do |prompt|
                  suggestions_for_input_and_prompt(input:, prompt:)
                end
              )
            end
          )
        end
      end

      private def suggestions_for_input_and_prompt(input:, prompt:)
        (suggestions_by_input[input] || []).select do |suggestion|
          suggestion.prompt_id == prompt.id
        end
      end

      private def inputs_for_activity_and_question(activity:, question:)
        (inputs_by_activity[activity] || []).select do |input|
          input.question_label == question.label
        end
      end

      private def inputs_by_activity
        @inputs_by_activity ||= suggestions_by_input.keys.group_by(&:activity)
      end

      private def suggestions_by_input
        @suggestions_by_input ||= grading_suggestions.group_by(
          &:grading_suggestion_input
        )
      end

      private def grading_suggestions
        @grading_suggestions ||= AI::GradingSuggestion.internal.where(
          prompt_id: comparison_prompts.map(&:id),
          program_id: program.id
        ).includes(:grading_suggestion_input)
      end

      private def routes
        Rails.application.routes.url_helpers
      end
    end
  end
end
