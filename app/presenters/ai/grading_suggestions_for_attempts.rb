module AI
  module GradingSuggestionsForAttempts
    def grading_suggestion_data_for(attempt, question_label)
      return empty_response unless attempt

      attempt_id = attempt.id

      {
        suggestions: suggestions_for(attempt_id, question_label),
        suggestion_job: job_for(attempt_id, question_label)
      }
    end

    def student_attempts
      "Presenters including #{method(__method__).owner} must define #{__method__}."
    end

    private def attempt_ids
      @attempt_ids ||= begin
        if student_attempts.is_a?(Hash)
          student_attempts.values.map(&:id)
        else
          student_attempts.map(&:id)
        end
      end
    end

    private def grouped_suggestions
      @grouped_suggestions ||= suggestions_by_attempt_id.transform_values do |values|
        values.group_by(&:question_label)
      end
    end

    private def job_for(attempt_id, question_label)
      grouped_jobs.dig(attempt_id, question_label)
    end

    private def jobs
      AI::GradingSuggestionJob.where(attempt_id: attempt_ids)
    end

    private def grouped_jobs
      @grouped_jobs ||= jobs.group_by(&:attempt_id).transform_values do |values|
        values.index_by(&:question_label)
      end
    end

    private def suggestions_by_attempt_id
      suggestions.group_by(&:attempt_id)
    end

    private def suggestions_for(attempt_id, question_label)
      grouped_suggestions.dig(attempt_id, question_label) || []
    end

    private def suggestions
      AI::GradingSuggestion.non_internal.where(attempt_id: attempt_ids)
    end

    private def empty_response
      {
        suggestions: [],
        suggestion_job: nil
      }
    end
  end
end
