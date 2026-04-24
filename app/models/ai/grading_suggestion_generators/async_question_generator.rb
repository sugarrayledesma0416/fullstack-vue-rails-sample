module AI
  module GradingSuggestionGenerators
    class AsyncQuestionGenerator
      attr_reader :attempt, :grading_suggestion_input, :question_label
      attr_writer :prompt

      def initialize(attempt:, question_label:, grading_suggestion_input:, prompt: nil)
        @attempt = attempt
        @question_label = question_label
        @grading_suggestion_input = grading_suggestion_input
        self.prompt = prompt
      end

      def generate
        if activity.includes_activity_type?('open_ended')
          job = GradingSuggestionJob.find_or_initialize_by(
            attempt_id: attempt.id,
            question_label: question_label
          )
          job.status = 'in_progress'
          job.save!

          AI::GradingSuggestionGenerators::OpenEndedQuestionGeneratorWorker.perform_async(
            attempt.id,
            question_label,
            prompt.id,
            job.id,
            grading_suggestion_input&.id
          )
        end
        if activity.includes_activity_type?('composition')
          job = GradingSuggestionJob.find_or_initialize_by(
            attempt_id: attempt.id,
            question_label: question_label
          )
          job.status = 'in_progress'
          job.save!

          AI::GradingSuggestionGenerators::CompositionQuestionGeneratorWorker.perform_async(
            attempt.id,
            question_label,
            prompt.id,
            job.id,
            grading_suggestion_input&.id
          )
        end
      end

      private def activity
        attempt.activity
      end

      private def prompt
        @prompt ||= AI::GradingSuggestionPrompt.current
      end
    end
  end
end
