class QuestionBankTopicsConcept < ApplicationRecord
  belongs_to :concept
  belongs_to :question_bank_topic

  validates(
    :concept_id,
    uniqueness: {
      scope: :question_bank_topic_id,
      case_sensitive: true,
      message: lambda do |object, _data|
        "#{object.concept.name} with ID #{object.concept.id} is already mapped to " \
          "#{object.question_bank_topic.name}."
      end
    }
  )
end
