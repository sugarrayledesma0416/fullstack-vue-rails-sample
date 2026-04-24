module AI
  class GradingSuggestionWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 3

    def perform(attempt_ids)
      attempts = Attempt.where(id: attempt_ids)

      attempt_ids_with_jobs = AI::GradingSuggestionJob.where(attempt_id: attempts.pluck(:id),
                                                             status: %i[
                                                               completed failed_empty_response
                                                             ]).pluck(:attempt_id).uniq

      missing_attempts = attempts.reject { |a| attempt_ids_with_jobs.include?(a.id) }

      missing_attempts.each do |attempt|
        AI::OverallCommentGenerators::ActivityGenerator.new(
          attempt:, grading_suggestion_input: nil
        ).generate
        AI::GradingSuggestionGenerators::ActivityGenerator.new(
          attempt:, grading_suggestion_input: nil
        ).generate
      end
    end
  end
end
