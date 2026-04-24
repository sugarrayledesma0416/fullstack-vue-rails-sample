describe Lti::DashboardDeepLinkJwt do
  let(:claims) { GradebookEngine::Lti::Constants::CLAIMS }
  let(:deployment_id) { SecureRandom.hex(10) }
  let(:program) { create(:program) }
  let(:platform) { create(:lti_platform) }
  let(:private_key) { Rails.configuration.lti_tool_private_keys.first }
  let(:public_key) { private_key.public_key }
  let(:ua_url) { 'https://testenv.vhlcentral.com/' }
  let(:launch) do
    create(
      :lti_launch,
      deep_linking_settings: {},
      deployment_id:,
      platform:
    )
  end

  describe '#to_h' do
    before do
      stub_const('UA_URL', ua_url)
      allow(STATS_PROXY).to receive(:info)
    end

    def result
      jwt = described_class.new(program.id, launch.guid).to_h[:jwt]
      JWT.decode(jwt, public_key, true, algorithm: 'RS256').first
    end

    it 'logs an lti event' do
      described_class.new(program.id, launch.guid).to_h

      expect(STATS_PROXY).to have_received(:info).with(
        hash_including(
          extra: hash_including(
            claims[:content_item] => contain_exactly(
              hash_including(
                custom: {
                  program_id: program.id, view: 'dashboard'
                }
              )
            )
          ),
          launch_guid: launch.guid,
          platform_guid: platform.guid
        )
      )
    end

    it 'has the client_id of the platform as the issuer id' do
      expect(result['iss']).to eq(platform.client_id)
    end

    it 'has the issuer_id of the platform as the audience' do
      expect(result['aud']).to eq(platform.issuer_id)
    end

    it 'has a message type of LtiDeepLinkingResponse' do
      expect(result[claims[:message_type]]).to eq('LtiDeepLinkingResponse')
    end

    it 'has an LTI version of 1.3.0' do
      expect(result[claims[:lti_version]]).to eq('1.3.0')
    end

    it 'has the deployment id of the launching platform' do
      expect(result[claims[:deployment_id]]).to eq(deployment_id)
    end

    context 'when the launch jwt has no data key in the deep link settings,' do
      it 'has no deep-linking data claim' do
        expect(result).not_to have_key(claims[:deep_linking_data])
      end
    end

    context 'when the launch jwt has a data key in the deep link settings,' do
      let(:data_string) { SecureRandom.uuid }
      let(:launch) do
        create(
          :deep_linking_lti_launch,
          deep_linking_settings: { data: data_string },
          deployment_id:,
          platform:
        )
      end

      it 'has a data claim with the same value as data key of the launch jwt' do
        expect(result[claims[:deep_linking_data]]).to eq(data_string)
      end
    end

    it 'has a content item that includes the program id' do
      title = 'Current Assignments'

      expect(result[claims[:content_item]]).to contain_exactly(
        'custom' => {
          'program_id' => program.id, 'view' => 'dashboard'
        },
        'title' => title,
        'type' => 'ltiResourceLink',
        'url' => "#{UA_URL}lti/resource_link?program_id=#{program.id}" \
                 '&view=dashboard'
      )
    end
  end
end
