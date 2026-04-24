describe Lti::Launch do
  let(:claims) { GradebookEngine::Lti::Constants::CLAIMS }

  describe '.dangerfield_exclude_on_update' do
    let(:platform) { create(:lti_platform) }
    let(:valid_attrs) do
      {
        'decoded_jwt' => {},
        'guid' => SecureRandom.uuid,
        'lti_platform_guid' => platform.guid,
        'sync_token' => 123_456
      }
    end
    let(:launch) { described_class.new }

    it 'accepts new instance if a jwt attribute is present' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.merge('jwt' => 'some encoded jwt'),
          launch
        )

        expect(launch.guid).to eq(valid_attrs['guid'])
      end
    end

    it 'accepts new instance if a state attribute is present' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.merge('state' => 'some state'),
          launch
        )

        expect(launch.guid).to eq(valid_attrs['guid'])
      end
    end

    it 'accepts new instance if an lti_tool_id attribute is present' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.merge('lti_tool_id' => 'some-id'),
          launch
        )

        expect(launch.guid).to eq(valid_attrs['guid'])
      end
    end
  end

  describe 'dangerfield_reject_if' do
    let(:platform) { create(:lti_platform) }
    let(:valid_attrs) do
      {
        'guid' => SecureRandom.uuid,
        'lti_platform_guid' => platform.guid,
        'request_id' => SecureRandom.uuid,
        'sync_token' => 123_456
      }
    end
    let(:launch) { described_class.new }

    it 'accepts new instance if the associated platform exists' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(valid_attrs, launch)
        expect(launch.guid).not_to be_nil
      end
    end

    it 'rejects new instance if the associated platform does not exist' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.merge('lti_platform_guid' => 'invalid guid'),
          launch
        )
        expect(launch.guid).to be_nil
      end
    end

    it 'rejects new instance if there is no lti_platform_guid attribute in the params' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.except('lti_platform_guid'),
          launch
        )
        expect(launch.guid).to be_nil
      end
    end
  end

  describe '#deployment_id' do
    it 'returns the value of the deployment id' do
      deployment_id = SecureRandom.hex(10)
      launch = create(:lti_launch, deployment_id:)

      expect(launch.deployment_id).to eq(deployment_id)
    end
  end

  describe '#platform_user_id' do
    it 'returns the value of the lms_user_id' do
      lms_id = SecureRandom.hex(10)

      launch = create(:lti_launch, lms_user_id: lms_id)
      expect(launch.platform_user_id).to eq(lms_id)
    end
  end

  describe '#deep_link_data' do
    it 'returns nil if there are no deep link settings in the jwt' do
      launch = create(:resource_link_lti_launch)

      expect(launch.deep_link_data).to be_nil
    end

    context 'when the jwt contains deep link settings,' do
      it 'returns nil if the settings have no data key' do
        launch = create(
          :deep_linking_lti_launch,
          deep_linking_settings: {}
        )
        expect(launch.deep_link_data).to be_nil
      end

      it 'returns the value of the data key in the settings' do
        data_string = SecureRandom.hex(10)
        launch = create(
          :deep_linking_lti_launch,
          deep_linking_settings: { data: data_string }
        )
        expect(launch.deep_link_data).to eq(data_string)
      end
    end
  end

  describe '#deep_link_return_url' do
    it 'returns nil if there are no deep link settings in the jwt' do
      launch = create(:resource_link_lti_launch)

      expect(launch.deep_link_return_url).to be_nil
    end

    context 'when the jwt contains deep link settings,' do
      it 'returns nil if the settings have no deep_link_return_url' do
        launch = create(
          :deep_linking_lti_launch,
          deep_linking_settings: {}
        )
        expect(launch.deep_link_return_url).to be_nil
      end

      it 'returns the value of the deep_link_return_url key in the settings' do
        valid_url = 'https://lms.example.com/deep_linking/return_url'
        launch = create(
          :deep_linking_lti_launch,
          deep_linking_settings: {
            deep_link_return_url: valid_url
          }
        )
        expect(launch.deep_link_return_url).to eq(valid_url)
      end
    end
  end
end
