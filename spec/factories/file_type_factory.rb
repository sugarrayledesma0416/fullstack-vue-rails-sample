FactoryBot.define do
  factory :file_type do
    created_at { Date.today }
    extension_name { generate(:extension) }
    extension_description { generate(:extension_description) }
  end

  factory :allowed_file_type, parent: :file_type do
    is_allowed { true }
  end

  sequence :extension do |index|
    FFaker::Lorem.words(1).first
  end

  sequence :extension_description do |index|
    FFaker::Company.catch_phrase
  end
end
