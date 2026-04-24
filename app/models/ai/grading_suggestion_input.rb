module AI
  class GradingSuggestionInput < ApplicationRecord
    self.table_name = 'ai_grading_suggestion_inputs'

    belongs_to :program
    belongs_to :activity
    belongs_to :attempt
    has_many(
      :grading_suggestions,
      class_name: 'AI::GradingSuggestion',
      inverse_of: :grading_suggestion_input,
      dependent: :destroy
    )
    has_many(
      :overall_comments,
      class_name: 'AI::OverallComment',
      inverse_of: :grading_suggestion_input,
      dependent: :destroy
    )

    validates(:question_label, presence: true)
    validates(:student_response, presence: true)

    before_validation :denormalize_program_id_and_activity_id

    private def denormalize_program_id_and_activity_id
      self.activity_id = attempt.activity_id
      self.program_id = attempt.activity.program.id
    end
  end
end
