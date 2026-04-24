module AI
  module GradingSuggestionGenerators
    class OpenEndedQuestionGeneratorWorker
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker

      sidekiq_options retry: false
      sidekiq_throttle(
        # limit number of concurrent jobs of this class
        concurrency: { limit: 100 }
      )

      def perform(attempt_id, question_label, prompt_id, job_id, grading_suggestion_input_id)
        attempt = Attempt.find(attempt_id)
        prompt = AI::GradingSuggestionPrompt.find(prompt_id)
        grading_suggestion_input = if grading_suggestion_input_id
                                     AI::GradingSuggestionInput.find(grading_suggestion_input_id)
                                   end

        AI::GradingSuggestionGenerators::OpenEndedQuestionGenerator.new(
          attempt:,
          grading_suggestion_input:,
          job_id:,
          prompt:,
          question_label:
        ).generate
      end
    end
  end
end
