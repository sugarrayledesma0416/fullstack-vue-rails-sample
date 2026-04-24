module AI
  module GradingSuggestionGenerators
    class OpenEndedActivityGenerator
      attr_reader :attempt, :grading_suggestion_input, :prompt
      attr_accessor :async

      def initialize(attempt:, grading_suggestion_input:, prompt:, async: true)
        @attempt = attempt
        @grading_suggestion_input = grading_suggestion_input
        @prompt = prompt
        self.async = async
      end

      def generate
        questions.each do |question|
          next unless question.is_a?(MaestroActivityEngine::ActivityContent::OpenEnded::Item)

          job = GradingSuggestionJob.find_or_initialize_by(
            attempt_id: attempt.id,
            question_label: question.label
          )

          unless attempt.results&.has_response?(question.label)
            job.status = :failed_empty_response
            job.error = "No response found for question #{question.label}"
            job.save!
            next
          end

          job.status = 'in_progress'

          job.save!

          worker_args = [attempt.id, question.label, prompt.id, job.id, grading_suggestion_input&.id]
          worker_class = AI::GradingSuggestionGenerators::OpenEndedQuestionGeneratorWorker

          if async
            worker_class.perform_async(*worker_args)
          else
            worker_class.perform_inline(*worker_args)
          end
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
