class StandardSet < ApplicationRecord
  before_save :set_defaults
  has_many(
    :standards,
    primary_key: :vendor_guid,
    foreign_key: :vendor_standard_set_guid,
    inverse_of: :standard_set,
    dependent: :nullify
  )

  validates :vendor_guid, presence: true, uniqueness: true
  validates :issuer, presence: true
  validates :name, presence: true

  # Open search works better with empty string instead of null so we
  # want to make sure we are not saving nil values
  private def set_defaults
    self.adopt_year = '' if adopt_year.nil?
    self.state = '' if state.nil?
    self.acronym = '' if acronym.nil?
    self.description = '' if description.nil?
  end
end
