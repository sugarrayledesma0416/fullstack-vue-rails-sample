FactoryBot.define do
  factory :standard_set do
    vendor_guid { SecureRandom.uuid }
    issuer { 'some issuer' }
    sequence(:name) { |index| 'Standard Set %03d' % index }
    sequence(:display_name) { |index| 'Issuer %03d' % index }
    adopt_year { 2020 }
    description { 'Some description' }
    acronym { 'ABC' }
  end
end
