class EReaderItem < ApplicationRecord
  self.table_name = 'ereader_items'
  has_one(
    :standard_asset,
    -> { where(reference_type: 'EReaderItem') },
    foreign_key: :reference_id,
    inverse_of: :ereader_item,
    dependent: :destroy
  )

  belongs_to :concept
  has_many :standards, through: :standard_asset
  validates :guid, presence: true

  delegate :lesson, to: :concept
  delegate :id, to: :lesson, prefix: true

  def assessment?
    false
  end

  def draft?
    false
  end

  def group_chat?
    false
  end

  def instructor_graded?
    false
  end

  def partner_chat?
    false
  end
end
