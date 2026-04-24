class GroupChatAssignmentConfig < ApplicationRecord
  USERS_RANGE = [2, 3, 4, 5, 6].freeze

  validate :validate_group_chat_config

  validates :assignment_id, presence: true
  validates :group_minimum, inclusion: {
    in: USERS_RANGE,
    message: '%{value} is not valid for group_minimum'
  }
  validates :group_maximum, inclusion: {
    in: USERS_RANGE,
    message: '%{value} is not valid for group_maximum'
  }

  belongs_to :assignment

  private def validate_group_chat_config
    unless group_maximum >= group_minimum
      errors.add(
        :group_maximum,
        "must be greater than group minimum, which is #{group_minimum}"
      )
    end
  end
end
