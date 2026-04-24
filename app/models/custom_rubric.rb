class CustomRubric < ApplicationRecord
  attr :stored_rubric

  belongs_to(
    :instructor_created_activity,
    foreign_key: :activity_id,
    inverse_of: :custom_rubrics,
    dependent: nil
  )

  belongs_to(
    :source_activity,
    class_name: 'Activity',
    inverse_of: :custom_rubrics,
    dependent: nil
  )
end
