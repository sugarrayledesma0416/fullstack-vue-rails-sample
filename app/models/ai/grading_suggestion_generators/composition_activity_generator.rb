module AI
  module GradingSuggestionGenerators
    class CompositionActivityGenerator
      attr_reader :attempt, :grading_suggestion_input, :prompt

      def initialize(attempt:, grading_suggestion_input:, prompt:)
        @attempt = attempt
        @grading_suggestion_input = grading_suggestion_input
        @prompt = prompt
      end

      def generate
        questions.each do |question|
          next unless question.is_a?(MaestroActivityEngine::ActivityContent::Composition::Item)

          job = GradingSuggestionJob.find_or_initialize_by(
            attempt_id: attempt.id,
            question_label: question.label,
          )

          unless attempt.results&.has_response?(question.label)
            job.status = :failed_empty_response
            job.error = "No response found for question #{question.label}"
            job.save!
            next
          end

          job.status = 'in_progress'

          job.save!

          AI::GradingSuggestionGenerators::CompositionQuestionGeneratorWorker.perform_async(
            attempt.id,
            question.label,
            prompt.id,
            job.id,
            grading_suggestion_input&.id
          )
        end
      end

      private def questions
        content_object.questions
      end

      private def content_object
        activity.content_object
      end

      private def activity
        attempt.activity
      end
    end
  end
end
