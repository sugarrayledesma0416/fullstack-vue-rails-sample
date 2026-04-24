class UserDefinedWordSerializer < ActiveModel::Serializer
  attributes :target, :definition, :translation, :lesson_id, :id, :pinyin

  def attributes
    data = super
    data[:topic] = 'My Words'
    data[:ascii] = object.ascii if object.ascii
    data
  end
end
