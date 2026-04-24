class StandardAlignment < ApplicationRecord
  belongs_to :standard_asset
  belongs_to :standard, primary_key: :vendor_guid, foreign_key: :vendor_standard_guid

  validates :standard_asset, uniqueness: { scope: :vendor_standard_guid }
end
