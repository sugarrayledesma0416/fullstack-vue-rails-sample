FactoryBot.define do
  factory :standard_alignment do
    standard_asset do |proxy|
      proxy.association(:standard_asset , standard_asset_id: proxy.id)
    end
    vendor_asset_guid { SecureRandom.uuid }
    vendor_standard_guid { SecureRandom.uuid }
    alignment_status  { 'aligned' }
  end
end

