class Standard < ApplicationRecord
  validates :vendor_guid, uniqueness: true
  before_save :set_defaults
  belongs_to(
    :standard_set,
    primary_key: :vendor_guid,
    foreign_key: :vendor_standard_set_guid,
    inverse_of: :standards
  )

  validates :vendor_guid, presence: true, uniqueness: true
  validates :description, presence: true

  delegate :display_number, to: :decorator

  def match_grade_levels?(program)
    additional_info = JSON.parse(self.additional_info, symbolize_names: true)
    grade_levels = additional_info[:additional_info][:grade_levels].split(',')
    program.standard_grade_levels.any? { |gl| grade_levels.include?(gl)  }
  end

  # Open search works better with empty string instead of null so we
  # want to make sure we are not saving nil values
  private def set_defaults
    self.name = '' if name.nil?
    self.label = '' if label.nil?
    self.number = '' if number.nil?
    self.additional_info = {} if additional_info.nil?
  end

  def decorator
    @decorator ||= StandardDecorator.new(self)
  end
end
