class AssignedAssessmentDetail < ApplicationRecord
  belongs_to :assignment

  before_save :strip_password

  # Attribute name "Password" is included in the validation message instead of
  # being automatically prefixed by Rails, because this attribute is set from
  # parent Assignment via nested attributes for. See
  # Assignment.human_attribute_name for more details.
  validates :password, length: {
    maximum: 255,
    too_long: 'Password length must be less than %{count}.'
  }

  validate :time_limit_validation

  def strip_password
    self.password = self.password.try(:strip)
  end

  def time_limit
    attributes['time_limit'].to_i
  end

  private def time_limit_validation
    return unless time_limit.negative? || time_limit == 1

    errors.add(:time_limit, 'Time limit must be a minimum of 2 minutes.')
  end
end
