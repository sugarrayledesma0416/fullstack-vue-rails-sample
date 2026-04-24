class AssessmentItem < ApplicationRecord
  has_one(
    :standard_asset,
    -> { where(reference_type: 'AssessmentItem') },
    foreign_key: :reference_id,
    inverse_of: :assessment_item,
    dependent: :destroy
  )

  belongs_to :assessment, class_name: 'Activity', primary_key: :cms_activity_id
  has_many :standards, through: :standard_asset
  validates :guid, presence: true
end
