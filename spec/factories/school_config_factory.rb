FactoryBot.define do
  factory :school_config do
    chat_support_disabled { false }
    association :school, factory: :school
    school_content_sharing { true }
    program_content_sharing_json { {} }
  end

  factory :school_config_with_portfolio, parent: :school_config do
    web_token { 'sampletoken1234' }
    institute_short_name { 'vhl' }
  end
end
