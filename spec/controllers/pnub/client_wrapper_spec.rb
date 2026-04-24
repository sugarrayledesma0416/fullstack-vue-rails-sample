describe Pnub do
  let(:user) { build(:student) }
  let(:auth_token) { 'b153156f8d3ff1317066' }
  let(:pn_client) { instance_double(Pubnub::Client) }
  let(:channels) { %w[channel-1 channel-2] }
  let(:grant_opts) { { auth_token:, client: pn_client } }

  # for grants, pubnub sends a response that response to .status[:code]
  let(:response_200) { instance_double(Pubnub::Envelope, status: { code: 200 }) }
  let(:response_403) do
    instance_double(Pubnub::Envelope, status: { code: 403 }, result: 'foo')
  end

  def expect_read_write_grant(auth_token, pn_client)
    expect(Pnub::ReadWriteGrant).to have_received(:new).with(
      anything,
      auth_token:,
      client: pn_client,
      ttl: Pnub::ClientWrapper::DEFAULT_GRANTS_TTL
    )
  end

  def expect_write_grant(auth_token, pn_client)
    expect(Pnub::WriteGrant).to have_received(:new).with(
      anything,
      auth_token:,
      client: pn_client,
      ttl: Pnub::ClientWrapper::DEFAULT_GRANTS_TTL
    )
  end

  def expect_read_grant(auth_token, pn_client)
    expect(Pnub::ReadGrant).to have_received(:new).with(
      anything,
      auth_token:,
      client: pn_client,
      ttl: Pnub::ClientWrapper::DEFAULT_GRANTS_TTL
    )
  end

  before do
    allow(SecureRandom).to receive(:hex).and_return(auth_token)
  end

  describe Pnub::ClientWrapper do
    let(:section_group_info) { { id: 'section_1' } }

    let(:grant_roster_with_groups) do
      { roster: { groups: [section_group_info] }, user: { uuid: user.guid } }
    end

    let(:empty_grant_roster) do
      { roster: { groups: [] }, user: { uuid: user.guid } }
    end

    let(:read_write_grant) do
      instance_double(
        Pnub::ReadWriteGrant,
        ddog_dispatch: nil,
        dispatch: nil,
        grant: nil,
        grant_latency: 0,
        grant_type: 'read_write_grant',
        success: true
      )
    end

    let(:write_grant) do
      instance_double(
        Pnub::WriteGrant,
        ddog_dispatch: nil,
        dispatch: nil,
        grant: nil,
        grant_latency: 0,
        grant_type: 'write_grant',
        success: true
      )
    end

    let(:read_grant) do
      instance_double(
        Pnub::ReadGrant,
        ddog_dispatch: nil,
        dispatch: nil,
        grant: nil,
        grant_latency: 0,
        grant_type: 'read_grant',
        success: true
      )
    end

    before do
      allow(STATS_PROXY).to receive(:relay)
      allow(Pubnub).to receive(:new).and_return(pn_client)
      allow(pn_client).to receive(:grant).and_return(response_200)
      allow(Pnub::ReadWriteGrant).to receive(:new).and_return(read_write_grant)
      allow(Pnub::WriteGrant).to receive(:new).and_return(write_grant)
      allow(Pnub::ReadGrant).to receive(:new).and_return(read_grant)
    end

    describe '#create_grants' do
      context 'when the user has groups to be granted,' do
        before do
          allow(user).to receive(:pubnub_grants_roster)
            .and_return(grant_roster_with_groups)
          described_class.new(user).create_grants
        end

        it 'creates a read-write grant with the default ttl' do
          expect_read_write_grant(auth_token, pn_client)
        end

        it 'creates a write grant with the default ttl' do
          expect_write_grant(auth_token, pn_client)
        end

        it 'creates a read grant with the default ttl' do
          expect_read_grant(auth_token, pn_client)
        end
      end

      context 'when the user is performing SVR and has no grants' do
        before do
          allow(user).to receive(:active_courses_pubnub_grants_roster)
            .and_return(grant_roster_with_groups)
          described_class.new(user, 'solo_video_recording').create_grants
        end

        it 'creates a read-write grant with the default ttl' do
          expect_read_write_grant(auth_token, pn_client)
        end

        it 'creates a write grant with the default ttl' do
          expect_write_grant(auth_token, pn_client)
        end

        it 'creates a read grant with the default ttl' do
          expect_read_grant(auth_token, pn_client)
        end
      end

      it 'does not create grants when the user has no groups to be granted' do
        allow(user).to receive(:pubnub_grants_roster)
          .and_return(empty_grant_roster)

        described_class.new(user).create_grants

        [Pnub::ReadWriteGrant, Pnub::WriteGrant, Pnub::ReadGrant].each do |klass|
          expect(klass).not_to have_received(:new)
        end
      end
    end

    describe '#grants_successful?' do
      # rubocop:disable RSpec/PredicateMatcher
      # because client.be_grants_successful looks funny.
      context 'when the user has groups to be granted,' do
        before do
          allow(user).to receive(:pubnub_grants_roster)
            .and_return(grant_roster_with_groups)
        end

        it 'is true when all of the grants are successful' do
          client = described_class.new(user)
          client.create_grants

          expect(client.grants_successful?).to be_truthy
        end

        it 'is false when some grants are not successful' do
          allow(write_grant).to receive(:success).and_return(false)
          allow(write_grant).to receive(:error_response).and_return({})

          client = described_class.new(user)
          client.create_grants

          expect(client.grants_successful?).to be_falsey
        end
      end

      it 'is false when the user has no groups to be granted' do
        allow(user).to receive(:pubnub_grants_roster)
          .and_return(empty_grant_roster)

        client = described_class.new(user)
        client.create_grants
        expect(client.grants_successful?).to be_falsey
      end
      # rubocop:enable RSpec/PredicateMatcher
    end

    describe '#grant_responses_with_errors' do
      it 'is nil if no grant attempts were made' do
        allow(user).to receive(:pubnub_grants_roster)
          .and_return(empty_grant_roster)

        client = described_class.new(user)
        client.create_grants

        expect(client.grant_responses_with_errors).to be_nil
      end

      context 'when grant attempts are made' do
        before do
          allow(user).to receive(:pubnub_grants_roster)
            .and_return(grant_roster_with_groups)
        end

        it 'is an empty JSON array if all grant attempts were successful' do
          client = described_class.new(user)
          client.create_grants

          expect(JSON.parse(client.grant_responses_with_errors)).to eq([])
        end

        it 'returns the error response from each failed grant' do
          failed_write_response = 'write_failed'
          allow(write_grant).to receive(:success).and_return(false)
          allow(write_grant).to receive(:error_response)
            .and_return(failed_write_response)

          client = described_class.new(user)
          client.create_grants

          expect(JSON.parse(client.grant_responses_with_errors)).to eq(
            [failed_write_response]
          )
        end
      end
    end

    describe '#chat_session_data' do
      let(:chat_enabled_course_info) { { id: 1, chat_level: 'partner_chat' } }
      let(:chat_disabled_course_info) { { id: 2, chat_level: 'disabled' } }

      let(:client_roster) do
        {
          roster: {
            groups: [chat_enabled_course_info, chat_disabled_course_info]
          }
        }
      end

      let(:results) { described_class.new(user).chat_session_data }

      before do
        allow(user).to receive(:pubnub_client_roster).and_return(client_roster)
      end

      it 'includes an "auth_token" attribute with a generated auth token' do
        expect(results[:auth_token]).to eq(auth_token)
      end

      it 'includes a "provider" attribute set to "pubnub"' do
        expect(results[:provider]).to eq('pubnub')
      end

      it 'includes a "pubnub" attribute with publish and subscribe keys' do
        expect(results[:pubnub]).to eq(
          publish_key: M3::Application.config.pubnub[:pub_key],
          subscribe_key: M3::Application.config.pubnub[:sub_key]
        )
      end

      it 'includes a "roster" key containing only courses with chat enabled' do
        expect(results[:roster][:groups]).to eq(
          [chat_enabled_course_info]
        )
      end
    end
  end

  describe Pnub::AbstractGrant do
    # Testing of common AbstractGrant functionality is done using ReadGrant
    # sub-class.
    describe '#grant' do
      it 'defines a circuit breaker to protect vhl from pubnub grant service problems' do
        allow(pn_client).to receive(:grant).and_return(response_200)
        allow(Circuitbox).to receive(:circuit).and_return(
          instance_double(Circuitbox::CircuitBreaker, run!: true)
        )

        Pnub::ReadGrant.new(channels, **grant_opts).grant

        expect(Circuitbox).to have_received(:circuit).with(:pubnub_grant, anything)
      end

      context 'when the circuit breaker detects an error,' do
        let(:error_message) { 'Grant timeout' }
        let(:error) { StandardError.new(error_message) }

        before do
          allow(pn_client).to receive(:grant).and_raise(error)
          allow(VHLMonitor).to receive(:notify)
        end

        it 'dispatches the error to VHLMonitor' do
          Pnub::ReadGrant.new(channels, **grant_opts).grant

          expect(VHLMonitor).to have_received(:notify).with(error)
        end

        it 'sets an error response from the exception message' do
          grant = Pnub::ReadGrant.new(channels, **grant_opts)
          grant.grant

          expect(grant.success).to be_falsey
        end

        it 'sets success status to false' do
          grant = Pnub::ReadGrant.new(channels, **grant_opts)
          grant.grant

          expect(grant.error_response).to eq(
            code: 403,
            data: { message: error_message }
          )
        end
      end

      it 'calls grant on the Pubnub client' do
        allow(pn_client).to receive(:grant).and_return(response_200)
        Pnub::ReadGrant.new(channels, **grant_opts).grant

        expect(pn_client).to have_received(:grant).with(
          hash_including(auth_key: auth_token, channels: channels)
        )
      end

      context 'when the number of channels surpass 200' do
        let(:too_many_channels) { 400.times.map { |n| "channel_#{n}" } }
        let(:total_calls_made) { too_many_channels.size / 200 }

        it 'does grant calls for every batch of 200 channels' do
          allow(pn_client).to receive(:grant).and_return(response_200)

          Pnub::ReadGrant.new(too_many_channels, **grant_opts).grant

          expect(pn_client).to have_received(:grant).exactly(total_calls_made)
        end

        it 'saves the response for every grant call made if there is at least one error' do
          allow(pn_client).to receive(:grant).and_return(response_403).exactly(total_calls_made)

          grant = Pnub::ReadGrant.new(too_many_channels, **grant_opts)
          grant.grant

          expect(grant.error_response.size).to eq(total_calls_made)
        end
      end

      context 'when the grant is successful' do
        it 'sets success status to true' do
          allow(pn_client).to receive(:grant).and_return(response_200)

          grant = Pnub::ReadGrant.new(channels, **grant_opts)
          grant.grant

          expect(grant.success).to be_truthy
        end
      end

      context 'when the grant is unsuccessful,' do
        before do
          allow(pn_client).to receive(:grant).and_return(response_403)
        end

        it 'sets success status to false' do
          grant = Pnub::ReadGrant.new(channels, **grant_opts)
          grant.grant

          expect(grant.success).to be_falsey
        end

        it 'sets an error response from the client response' do
          grant = Pnub::ReadGrant.new(channels, **grant_opts)
          grant.grant

          expect(grant.error_response).to eq([response_403.result])
        end
      end
    end
  end

  describe Pnub::ReadWriteGrant do
    describe '#grant' do
      it 'calls grant on the Pubnub client with read and write both set to true' do
        allow(pn_client).to receive(:grant).and_return(response_200)

        grant = described_class.new(channels, **grant_opts)
        grant.grant

        expect(pn_client).to have_received(:grant).with(
          hash_including(read: true, write: true)
        )
      end
    end
  end

  describe Pnub::WriteGrant do
    describe '#grant' do
      it 'calls grant on the Pubnub client with read false and write true' do
        allow(pn_client).to receive(:grant).and_return(response_200)

        grant = described_class.new(channels, **grant_opts)
        grant.grant

        expect(pn_client).to have_received(:grant).with(
          hash_including(read: false, write: true)
        )
      end
    end
  end

  describe Pnub::ReadGrant do
    describe '#grant' do
      it 'calls grant on the Pubnub client with read true and write false' do
        allow(pn_client).to receive(:grant).and_return(response_200)

        grant = described_class.new(channels, **grant_opts)
        grant.grant

        expect(pn_client).to have_received(:grant).with(
          hash_including(read: true, write: false)
        )
      end
    end
  end

  describe Pnub::ChannelSet do
    let(:groups) do
      [
        { id: 'course_1', name: 'course_1' },
        { id: 'course_2', name: 'course_2' },
        { id: 'course_3', name: 'course_3' }
      ]
    end

    let(:channels) { described_class.new(user.guid, groups) }

    describe '#r_w_channels' do
      it 'produces the correct channels for the given groups' do
        expect(channels.r_w_channels).to eq(
          [
            'course_1', 'gs_course_1.*',
            'course_2', 'gs_course_2.*',
            'course_3', 'gs_course_3.*'
          ]
        )
      end
    end

    describe '#write_channels' do
      it 'produces the correct channels for the given groups' do
        expect(channels.write_channels).to eq(
          [
            'gc_course_1.*',
            'gc_course_2.*',
            'gc_course_3.*',
            'gt_course_1.*',
            'gt_course_2.*',
            'gt_course_3.*'
          ]
        )
      end
    end

    describe '#read_channels' do
      it 'produces the correct channels for the given groups' do
        expect(channels.read_channels).to eq(
          [
            "gc_course_1.#{user.guid}",
            'course_1-pnpres',
            "gc_course_2.#{user.guid}",
            'course_2-pnpres',
            "gc_course_3.#{user.guid}",
            'course_3-pnpres',
            "gt_course_1.#{user.guid}",
            'course_1-pnpres',
            "gt_course_2.#{user.guid}",
            'course_2-pnpres',
            "gt_course_3.#{user.guid}",
            'course_3-pnpres'
          ]
        )
      end
    end
  end
end
