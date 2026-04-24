class CourseSerializer < ActiveModel::Serializer
  attributes :id, :name, :program_id, :owner_id, :level, :allow_individual_assign,
             :first_unit_id, :last_unit_id, :start_date, :end_date, :errors,
             :any_due_dates_reached?, :assignments?, :ai_virtual_chat_level
  has_many :categories

  def errors
    object.errors.empty? ? [] : object.errors.full_messages
  end
end
