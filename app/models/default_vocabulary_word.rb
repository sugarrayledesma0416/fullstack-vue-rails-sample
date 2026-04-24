class DefaultVocabularyWord < ApplicationRecord

  include Asciiable

  scope :by_unit, ->(unit_id) { joins(:lesson).where(lessons: {unit_id: unit_id}) }

  belongs_to :program
  belongs_to :lesson
  serialize :audio_paths
  validates_presence_of :program_id, :lesson_id, :composite_dictionary_id,
                        :topic, :target, :translation
  validates(
    :composite_dictionary_id,
    format: { with: /\d+(:\d+)+/ },
    uniqueness: { scope: :program_id, case_sensitive: true }
  )

  def as_json(options=nil)
    DefaultVocabularyWordSerializer.new(self).as_json(root: false)
  end

end
