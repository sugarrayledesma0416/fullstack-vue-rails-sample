class StandardAsset < ApplicationRecord
  ACTIVITY_REFERENCE = 'Activity'.freeze
  ASSESSMENT_ITEM_REFERENCE = 'AssessmentItem'.freeze
  EREADER_ITEM_REFERENCE = 'EReaderItem'.freeze
  REFERENCE_TYPES = [ACTIVITY_REFERENCE, ASSESSMENT_ITEM_REFERENCE, EREADER_ITEM_REFERENCE].freeze
  has_many :standard_alignments, dependent: :destroy
  has_many :standards, through: :standard_alignments
  belongs_to(
    :activity,
    -> { includes(:standard_asset).where(standard_assets: { reference_type: 'Activity' }) },
    foreign_key: :reference_id,
    primary_key: :cms_activity_id,
    inverse_of: :standard_asset,
    optional: true
  )

  belongs_to(
    :assessment_item,
    -> { includes(:standard_asset).where(standard_assets: { reference_type: 'AssessmentItem' }) },
    foreign_key: :reference_id,
    inverse_of: :standard_asset,
    optional: true
  )

  belongs_to(
    :ereader_item,
    -> { includes(:standard_asset).where(standard_assets: { reference_type: 'EReaderItem' }) },
    class_name: 'EReaderItem',
    foreign_key: :reference_id,
    inverse_of: :standard_asset,
    optional: true
  )

  accepts_nested_attributes_for :assessment_item
  accepts_nested_attributes_for :ereader_item

  validates :vendor_guid, presence: true, uniqueness: true

  # called when an activity is published to m3;
  # the published status needs to be updated if the
  # activity/assessment/assessmentitem is represented by one or more
  # StandardAssets
  def self.update_published_status(cms_activity_id)
    # lookup StandardAsset where reference type = 'Activity'
    # and reference_id = cms_activity_id
    standard_assets = StandardAsset.where(reference_type: ACTIVITY_REFERENCE,
                                          reference_id: cms_activity_id)
    # if not found, check the AssessmentItems table
    # where assessment_id = cms_activity_id, will be one or more
    # AssessmentItems.(multiple AI = multiple StandardAssets)
    if standard_assets.empty?
      assessment_items = AssessmentItem.where(assessment_id: cms_activity_id)
      if assessment_items.present?
        standard_assets = StandardAsset.where(reference_type: ASSESSMENT_ITEM_REFERENCE,
                                              reference_id: assessment_items.pluck(:id))
      end
    end
    standard_assets.map do |std_asset|
      std_asset.update_column(:m3_publish_status, true)
    end
  end

  # receive a hash and convert to JSON for storage
  def additional_attrs=(value)
    self[:additional_attrs] = JSON.generate(value) if value.present?
  end

  # return the JSON value as a hash
  def additional_attrs
    additional_attrs = read_attribute(:additional_attrs)
    if additional_attrs.present?
      JSON.parse(additional_attrs, { symbolize_names: true })
    else
      {}
    end
  end

  def activity_reference?
    reference_type == StandardAsset::ACTIVITY_REFERENCE
  end

  def assessment_item_reference?
    reference_type == StandardAsset::ASSESSMENT_ITEM_REFERENCE
  end

  def ereader_item_reference?
    reference_type == StandardAsset::EREADER_ITEM_REFERENCE
  end

  def cms_activity_id_for_activity
    return unless activity_reference?

    reference_id
  end

  def cms_activity_id_for_assessment_item
    return unless assessment_item_reference?

    assessment_item&.assessment_id
  end
end
