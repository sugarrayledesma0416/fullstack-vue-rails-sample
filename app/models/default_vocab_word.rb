class DefaultVocabWord < ApplicationRecord
  belongs_to :program
  belongs_to :vocab_program_group, optional: true
  belongs_to :lesson
  # needs to be a vocab_tags association because of angular
  has_many :vocab_tags, class_name: 'DefaultVocabTag', dependent: :destroy
  has_many :vocab_words

  accepts_nested_attributes_for :vocab_tags, :allow_destroy => true

  validates_presence_of :language
  validates_presence_of :program_id
  validates_presence_of :target_word
  validates_presence_of :base_word
  # validates_presence_of :target_definition
end
