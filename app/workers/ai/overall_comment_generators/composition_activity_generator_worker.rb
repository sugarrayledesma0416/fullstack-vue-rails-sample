module AI
  module OverallCommentGenerators
    class CompositionActivityGeneratorWorker
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker

      sidekiq_options retry: false
      sidekiq_throttle(
        # limit number of concurrent jobs of this class
        concurrency: { limit: 100 }
      )

      def perform(attempt_id, prompt_id, grading_suggestion_input_id)
        attempt = Attempt.find(attempt_id)
        prompt = AI::OverallCommentPrompt.find(prompt_id)
        grading_suggestion_input = if grading_suggestion_input_id
                                     AI::GradingSuggestionInput.find(grading_suggestion_input_id)
                                   end

        AI::OverallCommentGenerators::CompositionActivityGenerator.new(
          attempt:,
          grading_suggestion_input:,
          prompt:
        ).generate
      end
    end
  end
end
