class VocabTag < ApplicationRecord
  validates :name, presence: true
  validates(
    :name,
    uniqueness: {
      scope: :vocab_word_id,
      case_sensitive: true
    }
  )
  belongs_to :vocab_word
end
