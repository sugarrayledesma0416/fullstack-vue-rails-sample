class VocabProgramGroup < ApplicationRecord
  has_many :programs
  has_many :default_vocab_words
  has_many :vocab_words
end
