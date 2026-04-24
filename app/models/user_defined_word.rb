class UserDefinedWord < ApplicationRecord

  include Asciiable
  belongs_to :program
  belongs_to :lesson
  belongs_to :user

  validates :target, presence: true
  validates :translation, presence: true

  scope :by_unit, ->(unit_id) { joins(:lesson).where(lessons: {unit_id: unit_id}) }

  def self.human_attribute_name(attribute_key_name, options={})
    case attribute_key_name.to_s
    when 'target' then 'Foreign word'
    when 'translation' then 'English word'
    else
      super
    end
  end

  def as_json(opts = {})
    UserDefinedWordSerializer.new(self).as_json(root: false)
  end
end
