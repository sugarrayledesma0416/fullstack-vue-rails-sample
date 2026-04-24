FactoryBot.define do
  factory(:resource_link_lti_launch, class: 'Lti::Launch') do
    deep_linking_settings { {} }
    deployment_id { 'valid-deployment-id' }
    guid { SecureRandom.uuid }
    lms_user_id { 'user-id' }

    association :platform, factory: :lti_platform
  end

  factory(:deep_linking_lti_launch, class: 'Lti::Launch') do
    deep_linking_settings do
      {
        deep_link_return_url: 'https://example.com/return_url',
        accept_presentation_document_targets: ['target'],
        accept_types: ['link']
      }
    end
    deployment_id { 'valid-deployment-id' }
    guid { SecureRandom.uuid }
    lms_user_id { 'user-id' }

    association :platform, factory: :lti_platform
  end

  factory(:lti_launch, parent: :resource_link_lti_launch)
end
