module AI
  class GradingSuggestion < ApplicationRecord
    ACCEPTED_STATUS = 'accepted'.freeze
    REJECTED_STATUS = 'rejected'.freeze

    self.table_name = 'ai_grading_suggestions'

    belongs_to :reviewed_by, class_name: 'User', optional: true
    belongs_to :program
    belongs_to :activity
    belongs_to :attempt

    belongs_to(
      :grading_suggestion_job,
      class_name: 'AI::GradingSuggestionJob',
      foreign_key: :ai_grading_suggestion_job_id,
      inverse_of: :grading_suggestions,
      optional: true
    )

    belongs_to(
      :prompt,
      class_name: 'AI::GradingSuggestionPrompt',
      optional: true
    )

    belongs_to(
      :grading_suggestion_input,
      class_name: 'AI::GradingSuggestionInput',
      optional: true
    )

    has_many(
      :ratings,
      class_name: 'AI::GradingSuggestionRating',
      dependent: :destroy,
      inverse_of: :grading_suggestion,
      foreign_key: :grading_suggestion_id
    )
    # Rating system for non internal records
    belongs_to :rated_by, class_name: 'User', optional: true
    belongs_to(
      :rating_category,
      class_name: 'AI::SuggestionRatingCategory',
      foreign_key: :rating_category_id,
      inverse_of: :grading_suggestions,
      optional: true
    )

    store(
      :suggestion_text,
      accessors: %i[
        incorrect_text
        error_explanation
        incorrect_text_begin_offset
      ],
      coder: JSON
    )

    validates(
      :incorrect_text,
      presence: true
    )
    validates(
      :error_explanation,
      presence: true
    )

    # The incorrect_text_begin_offset represents the offset of the start of the
    # incorrect_text in the student's response. It can be:
    # - blank for older records
    # - positive if the incorrect text is found in the student's response
    # - equal -1 if the incorrect text is not found in the student's response
    validates(
      :incorrect_text_begin_offset,
      numericality: {
        only_integer: true,
        greater_than_or_equal_to: -1
      },
      allow_blank: true
    )

    # A valid prompt is only required when creating a new record.
    validates(:prompt, presence: true, on: :create)
    validates(
      :error_explanation,
      :incorrect_text,
      :question_label,
      presence: true
    )

    # Review status is only for non internal records
    validates(
      :reviewed_status,
      absence: true,
      if: -> { grading_suggestion_input_id.present? }
    )
    validates(
      :reviewed_status,
      presence: true,
      if: -> { reviewed_by.present? },
      inclusion: {
        in: [ACCEPTED_STATUS, REJECTED_STATUS]
      }
    )
    validates(:reviewed_status, absence: true, if: -> { reviewed_by.blank? })

    # Rating category is only for non internal records
    validates(
      :rating_category,
      absence: true,
      if: -> { grading_suggestion_input_id.present? }
    )
    # Rating comment is only for non internal records
    validates(
      :rating_comment,
      absence: true,
      if: -> { grading_suggestion_input_id.present? }
    )
    validates(
      :rated_by,
      presence: true,
      if: -> { rating_category.present? || rating_comment.present? }
    )
    validates(
      :rated_by,
      absence: true,
      if: -> { rating_category.blank? && rating_comment.blank? }
    )

    before_validation(
      :denormalize_grading_suggestion_input_attributes,
      if: -> { grading_suggestion_input.present? }
    )

    before_validation do
      # Denormalize the language code attribute
      self.language_code = program.language_code if program.present?
    end

    before_save do
      if reviewed_status_changed? || (reviewed_by.present? && reviewed_by_id_changed?)
        # When we set the reviewer, automatically set the reviewed_at timestamp
        self.reviewed_at = reviewed_status.present? ? Time.current : nil
      end
      if rating_category_id_changed? || (rated_by.present? && rated_by_id_changed?)
        # When we set the rater, automatically set the timestamp
        self.rated_at = rating_category.present? ? Time.current : nil
      end
    end

    scope :non_internal, -> { where(grading_suggestion_input_id: nil) }
    scope :internal, -> { where.not(grading_suggestion_input_id: nil) }

    scope :with_prompt, -> (prompt_id) {
      where(prompt_id:) if prompt_id.present?
    }

    def accepted?
      reviewed_status == ACCEPTED_STATUS
    end

    def rejected?
      reviewed_status == REJECTED_STATUS
    end

    # Returns the offset of the character immediately following the end of the
    # incorrect text in the student's response.
    # If the begin offset is blank, it returns nil
    # If the begin offset is negative (text not found), it returns -1
    def incorrect_text_end_offset
      if incorrect_text_begin_offset.present?
        if incorrect_text_begin_offset >= 0
          incorrect_text_begin_offset + incorrect_text.length
        else
          -1
        end
      end
    end

    private def denormalize_grading_suggestion_input_attributes
      self.program_id = grading_suggestion_input.program_id
      self.activity_id = grading_suggestion_input.activity_id
      self.attempt_id = grading_suggestion_input.attempt_id
      self.question_label = grading_suggestion_input.question_label
    end
  end
end
