FactoryBot.define do
  factory(:lti_platform, class: Lti::Platform) do
    client_id { SecureRandom.uuid }
    guid { SecureRandom.uuid }
    issuer_id { 'https://lms.example.com' }
    keyset_url { 'https://lms.example.com/security/jwks' }
    lms_type { 'Canvas' }
    sequence(:name) { |index| "LtiPlatform #{index}" }
    oauth2_url { 'https://lms.example.com/oauth2/callback' }
    oidc_auth_url { 'https://lms.example.com/auth/oidc' }
    rostering { false }
    service_type { 'Self-Roster' }
    cartridge { false }
  end

  factory(:lti_rostering_platform, parent: :lti_platform) do
    rostering { true }
    service_type { 'Simple Roster' }
    school
  end

  factory(:lti_cartridge_platform, parent: :lti_platform) do
    cartridge { true }
    service_type { nil }
    school
  end
end
