module AI
  module OverallCommentGenerators
    class AsyncQuestionGenerator
      attr_reader :attempt, :grading_suggestion_input, :question_label
      attr_writer :prompt

      def initialize(attempt:, grading_suggestion_input:, question_label:, prompt: nil)
        @attempt = attempt
        @grading_suggestion_input = grading_suggestion_input
        @question_label = question_label
        self.prompt = prompt
      end

      def generate
        if activity.includes_activity_type?('open_ended')
          AI::OverallCommentGenerators::OpenEndedQuestionGeneratorWorker.perform_async(
            attempt.id,
            question_label,
            prompt.id,
            grading_suggestion_input&.id
          )
        end
        if activity.includes_activity_type?('composition')
          AI::OverallCommentGenerators::CompositionQuestionGeneratorWorker.perform_async(
            attempt.id,
            question_label,
            prompt.id,
            grading_suggestion_input&.id
          )
        end
      end

      private def activity
        attempt.activity
      end

      private def prompt
        @prompt ||= AI::OverallCommentPrompt.current
      end
    end
  end
end
