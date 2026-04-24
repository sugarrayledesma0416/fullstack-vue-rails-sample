FactoryBot.define do
  factory :standard_asset do
    vendor_guid { SecureRandom.uuid }
    reference_id { 123456 }
    reference_type { 'Activity' }
    m3_publish_status { true }
    date_alignments_modified_utc { nil }
    additional_attrs {
                       {
                         domain: 'Domain 1',
                         subdomain: 'Domain 1:Subdomain 1'
                       }
                     }
  end

  factory :standard_asset_assessment_item, parent: :standard_asset do
    association :assessment_item, factory: :assessment_item_with_assessment
    reference_type { 'AssessmentItem' }
  end

  factory :standard_asset_ereader_item, parent: :standard_asset do
    association :ereader_item, factory: :e_reader_item
    reference_type { 'EReaderItem' }
  end
end

