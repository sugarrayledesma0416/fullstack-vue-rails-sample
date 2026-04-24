class GroupSet < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: true }
  has_many :track_groups
end
