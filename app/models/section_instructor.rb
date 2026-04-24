class SectionInstructor < ApplicationRecord
  include Dangerfield::Publisher
  include Enterprise::SectionValidation

  belongs_to :section
  belongs_to :instructor, foreign_key: 'user_id'

  attr_writer :skip_section_id_validation

  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :section_id }

  delegate :email, :last_name, :last_name_first, to: :instructor

  scope :responsible, lambda {
    where(role: [INSTRUCTOR_ROLE, COINSTRUCTOR_ROLE, ASSISTANT_ROLE])
  }

  INSTRUCTOR_ROLE = 'Instructor'.freeze
  COINSTRUCTOR_ROLE = 'Co-instructor'.freeze
  ASSISTANT_ROLE = 'Assistant'.freeze
  INSTRUCTOR_ROLES = {
    none: '',
    co_instructor: COINSTRUCTOR_ROLE,
    assistant: ASSISTANT_ROLE
  }.freeze

  INSTRUCTOR_CREATOR_ROLES = { instructor: INSTRUCTOR_ROLE, assistant: ASSISTANT_ROLE }.freeze
  RESPONSIBLE_ROLES = { instructor: INSTRUCTOR_ROLE, co_instructor: COINSTRUCTOR_ROLE }.freeze

  def instructor
    User.unscoped { super }
  end
end
