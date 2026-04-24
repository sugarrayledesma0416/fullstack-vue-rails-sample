class QuestionBankTopic < ApplicationRecord
  has_many :question_banks, dependent: :nullify
  has_many :question_bank_topics_concepts, dependent: :destroy
  has_many :concepts, through: :question_bank_topics_concepts, source: :concept

  validates :name, :language, :level, presence: true

  def has_topic_concepts?
    question_bank_topics_concepts.any?
  end
end
