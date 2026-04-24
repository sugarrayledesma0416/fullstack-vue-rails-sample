module AI
  class SuggestionRatingDetail < ApplicationRecord
    self.table_name = 'ai_suggestion_rating_details'

    belongs_to :attempt
    belongs_to :program
    belongs_to :activity
    belongs_to :updated_by, class_name: 'User'

    validates(:question_label, presence: true)
    validates(:comment, presence: true)

    before_validation(:denormalize_program_and_activity)

    def comment=(value)
      super(value&.strip)
    end

    private def denormalize_program_and_activity
      self.activity_id = attempt&.activity_id
      self.program_id = attempt&.activity&.program&.id
    end
  end
end
