FactoryBot.define do
  factory(:lti_context_link, class: Lti::ContextLink) do
    context_id { SecureRandom.uuid }
    sequence(:context_label) { |index| "ContextLabel #{index}" }
    sequence(:context_title) { |index| "ContextTitle #{index}" }
    guid { SecureRandom.uuid }
    sequence(:line_items_url) do |index|
      "https://lms.example.com/api/lti/#{index}/line_items"
    end
    lti_platform
    platform_type { 'Canvas' }
    section
  end
end
