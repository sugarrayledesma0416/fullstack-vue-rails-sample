class DefaultVocabTag < ApplicationRecord
  belongs_to :default_vocab_word

  validates_presence_of :name
end
