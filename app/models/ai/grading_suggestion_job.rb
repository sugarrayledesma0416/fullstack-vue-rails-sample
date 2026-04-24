module AI
  class GradingSuggestionJob < ApplicationRecord
    self.table_name = 'ai_grading_suggestion_jobs'

    belongs_to :attempt

    scope :in_final_status, -> { where(status: ['failed', 'completed']) }

    has_many(
      :grading_suggestions,
      class_name: 'AI::GradingSuggestion',
      dependent: :nullify,
      foreign_key: :ai_grading_suggestion_job_id,
      inverse_of: :grading_suggestion_job
    )

    def failed?
      status == 'failed'
    end
  end
end
