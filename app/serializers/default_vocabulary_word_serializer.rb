class DefaultVocabularyWordSerializer < ActiveModel::Serializer
  attributes :target, :definition, :translation, :audio_paths, :lesson_id, :topic, :pinyin

  def attributes
    data = super
    data[:ascii] = object.ascii if object.ascii
    data
  end
end
