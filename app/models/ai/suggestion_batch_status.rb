module AI
  class SuggestionBatchStatus
    FINAL_STATUSES = %w[completed failed].freeze

    def initialize(activity_id, section_id)
      @activity_id = activity_id
      @section_id = section_id
    end

    def status
      attempt_ids = Attempt.where(activity_id: @activity_id, section_id: @section_id).pluck(:id)
      return 'ready' if attempt_ids.empty?

      # failed_empty_response is considered as completed because it means
      # the student's submission was empty and the AI wasn't able to generate a response
      # but it's still a valid attempt
      stats = AI::GradingSuggestionJob
        .where(attempt_id: attempt_ids)
        .select(
          'attempt_id',
          'COUNT(*) as total_jobs',
          "SUM(CASE WHEN status = 'completed' OR status = 'failed_empty_response' THEN 1 ELSE 0 END) as completed_count",
          "SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_count",
          "MAX(CASE WHEN status = 'completed' OR status = 'failed_empty_response' THEN 1 ELSE 0 END) as has_completed"
        )
        .group(:attempt_id)
        .having('COUNT(*) > 0')
        .to_a

      return 'processing' if stats.empty?

      total_attempts = stats.size
      all_failed = stats.all? { |s| s.failed_count == s.total_jobs }
      all_completed = stats.all? { |s| s.completed_count == s.total_jobs }
      any_completed = stats.any? { |s| s.has_completed == 1 }

      return 'failed' if all_failed && total_attempts == attempt_ids.size
      return 'ready' if all_completed && total_attempts == attempt_ids.size

      # If all jobs are in a terminal state, return 'completed'
      return 'completed' if stats.all? { |s| s.completed_count + s.failed_count == s.total_jobs }

      'processing'
    end
  end
end
