describe GbLtiPlatformMigrator do
  let(:auth_services_id) { 'https://old.authservices.id' }
  let(:m3_lti_platform) do
    create(:lti_platform, authorization_services_id: auth_services_id)
  end

  let(:add_update_args) do
    {
      action: 'add_update',
      id: m3_lti_platform.id,
      model_name: 'Lti::Platform'
    }
  end

  let(:migrator) { described_class.new(add_update_args) }

  describe '#update_object' do
    it 'creates a new gradebook Lti::Platform record when none exists' do
      migrator.update_object

      gb_object = GradebookEngine::Lti::Platform.find(m3_lti_platform.id)
      expect(gb_object).to have_attributes(
        authorization_services_id: auth_services_id,
        client_id: m3_lti_platform.client_id,
        disabled: m3_lti_platform.disabled,
        guid: m3_lti_platform.guid,
        issuer_id: m3_lti_platform.issuer_id,
        keyset_url: m3_lti_platform.keyset_url,
        lms_type: m3_lti_platform.lms_type,
        name: m3_lti_platform.name,
        oauth2_url: m3_lti_platform.oauth2_url,
        oidc_auth_url: m3_lti_platform.oidc_auth_url,
        service_type: m3_lti_platform.service_type
      )
    end

    it 'updates an existing gradebook Lti::Platform record' do
      # Create the original gradebook record
      migrator.update_object

      new_attrs = {
        authorization_services_id: 'https://new.authservices.id',
        client_id: 'new-client-id',
        disabled: true,
        guid: SecureRandom.uuid,
        issuer_id: 'https://new.issuer.id',
        keyset_url: 'https://new.keyset/url',
        lms_type: 'Moodle',
        name: 'new name',
        oauth2_url: 'https://new/oauth2.url',
        oidc_auth_url: 'https://new/oidc/url',
        service_type: 'Simple Roster'
      }

      m3_lti_platform.update!(new_attrs)

      migrator.update_object
      gb_object = GradebookEngine::Lti::Platform.find(m3_lti_platform.id)
      expect(gb_object).to have_attributes(new_attrs)
    end
  end
end
