FactoryBot.define do
  factory :school do
    name { 'VHL School' }
    city { 'Boston' }
    state { 'MA' }
    time_zone { 'Pacific Time (US & Canada)' }
    school_type { 'Default Type' }
    school_type_category { 1 }
    common_words_bitmap { 0 }
    clever_id { nil }
    parent_institution_id { nil }
    one_roster_integration_type { nil }
    sequence(:guid) { |_n| SecureRandom.uuid }
  end

  factory :district, parent: :school, class: 'District' do
    school_type { 'District' }
  end

  factory :clever_school, parent: :school do
    clever_id { generate(:clever_id) }
    district_clever_id { generate(:clever_id) }
    clever_integration_type { 'SSO' }
  end

  factory :clever_rostering_school, parent: :clever_school do
    clever_integration_type { 'Rostering' }
  end

  factory :one_roster_school, parent: :school do
    one_roster_integration_type { School::ONE_ROSTER_ROSTERING }
  end

  factory :one_roster_sso_school, parent: :school do
    one_roster_integration_type { School::ONE_ROSTER_SSO_ROSTERING }
  end

  factory :parent_institution, parent: :school, class: 'ParentInstitution'

  sequence :clever_id do |index|
    FFaker::Guid.guid
  end
end
