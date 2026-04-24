describe Lti::EventTracking do
  describe '#with_lti_event_tracking' do
    let(:event_class) { described_class::Event }
    let(:payload) { { a: 1, b: 2 } }
    let(:event) { instance_double(event_class, payload: payload) }
    let(:message) { 'my message' }
    let(:test_class) do
      Class.new do
        include Lti::EventTracking
      end
    end

    before do
      allow(event_class).to receive(:new).and_return(event)
      allow(STATS_PROXY).to receive(:info)
    end

    context 'when no errors are raised,' do
      it 'dispatches the specified message and event payload when called' \
         'without a block' do
        test_class.new.with_lti_event_tracking(message)

        expect(STATS_PROXY).to have_received(:info).with(
          hash_including(
            {
              application: :m3,
              environment: 'test',
              event_action: message,
              vhl_component: :lti
            }.merge(payload)
          )
        )
      end

      it 'dispatches the specified message and event payload' do
        test_class.new.with_lti_event_tracking(message) do
          _somevar = 1
        end

        expect(STATS_PROXY).to have_received(:info).with(
          hash_including(
            {
              application: :m3,
              environment: 'test',
              event_action: message,
              vhl_component: :lti
            }.merge(payload)
          )
        )
      end
    end

    context 'when an error is raised when assigning payload,' do
      let(:error_message) { 'Something bad happened' }

      before do
        allow(event).to receive(:payload).and_raise(StandardError, error_message)
      end

      it 'dispatches information about the error' do
        begin
          test_class.new.with_lti_event_tracking(message) do
            _somevar = 1
          end
        rescue StandardError => e
          # ignore the re-raised error if it is the expected error
          raise e unless e.message == error_message
        end

        expect(STATS_PROXY).to have_received(:info).with(
          hash_including(
            error_class: StandardError,
            error_message: error_message,
            error_location: /and_raise/
          )
        )
      end

      it 're-raises the error after capturing the error information' do
        expect do
          test_class.new.with_lti_event_tracking(message) do
            _somevar = 1
          end
        end.to raise_error(StandardError, error_message)
      end
    end

    context 'when an error is raised when yielding to the specified block' do
      let(:error_message) { 'Something worse happened' }

      it 'dispatches information about the error' do
        begin
          test_class.new.with_lti_event_tracking(message) do
            raise StandardError, error_message
          end
        rescue StandardError => e
          # ignore the re-raised error if it is the expected error
          raise e unless e.message == error_message
        end

        expect(STATS_PROXY).to have_received(:info).with(
          hash_including(
            error_class: StandardError,
            error_message: error_message,
            error_location: /#{__FILE__}/
          )
        )
      end

      it 're-raises the error after capturing the error information' do
        expect do
          test_class.new.with_lti_event_tracking(message) do
            raise StandardError, error_message
          end
        end.to raise_error(StandardError, error_message)
      end
    end
  end

  describe described_class::Event do
    describe '#payload' do
      it 'does not error if allowed objects are missing' do
        payload = described_class.new({}).payload
        expect(payload).to eq(
          context_id: nil,
          context_link: {},
          context_link_guid: nil,
          extra: {},
          launch: {},
          launch_guid: nil,
          params: {},
          platform: {},
          platform_guid: nil,
          platform_user_id: nil,
          section: {},
          section_guid: nil,
          session: {},
          user: {},
          user_guid: nil,
          user_link: {}
        )
      end

      describe 'critical index data' do
        it 'extracts context_id from the context_link if one is specified' do
          context_link = create(:lti_context_link)

          payload = described_class.new(context_link: context_link).payload

          expect(payload[:context_id]).to eq(context_link.context_id)
        end

        it 'has a nil context_id if no context_link is specified' do
          payload = described_class.new({}).payload

          expect(payload[:context_id]).to be_nil
        end

        it 'extracts context_link_guid from the context_link if one is ' \
           'specified' do
          context_link = create(:lti_context_link)

          payload = described_class.new(context_link: context_link).payload

          expect(payload[:context_link_guid]).to eq(context_link.guid)
        end

        it 'has a nil context_link_guid if no context_link is specified' do
          payload = described_class.new({}).payload

          expect(payload[:context_link_guid]).to be_nil
        end

        it 'extracts launch_guid from the launch if one is specified' do
          session_launch_guid = SecureRandom.uuid
          launch = create(:lti_launch)

          payload = described_class.new(
            launch: launch,
            session: { lti_deep_link_launch_guid: session_launch_guid  }
          ).payload

          # Extracting from the launch is prioritized over extracting
          # from session.
          expect(payload[:launch_guid]).to eq(launch.guid)
        end

        it 'extracts launch_guid from the session if no launch is specified' do
          session_launch_guid = SecureRandom.uuid

          payload = described_class.new(
            session: { lti_deep_link_launch_guid: session_launch_guid  }
          ).payload

          expect(payload[:launch_guid]).to eq(session_launch_guid)
        end

        it 'has a nil launch_guid if no launch is specified and no ' \
           'launch_guid is in the session' do
          payload = described_class.new({}).payload

          expect(payload[:launch_guid]).to be_nil
        end

        it 'extracts platform_guid from the platform if one is specified' do
          platform = create(:lti_platform)

          payload = described_class.new(platform: platform, session: {}).payload

          expect(payload[:platform_guid]).to eq(platform.guid)
        end

        it 'extracts the platform_guid from the platform associated with the ' \
           'specified context_link if no platform is specified' do
          platform = create(:lti_platform)
          context_link = create(:lti_context_link, lti_platform: platform)

          payload = described_class.new(context_link: context_link).payload

          expect(payload[:platform_guid]).to eq(platform.guid)
        end

        it 'extracts the platform_guid from the platform associated with the ' \
           'specified launch if no platform or context_link is specified' do
          platform = create(:lti_platform)
          launch = create(:lti_launch, platform:)

          payload = described_class.new(launch: launch).payload

          expect(payload[:platform_guid]).to eq(platform.guid)
        end

        it 'has a nil platform_guid if no platform, context_link or ' \
           'launch are specified' do
          payload = described_class.new({}).payload

          expect(payload[:platform_guid]).to be_nil
        end

        it 'extracts platform_user_id from the launch if one is specified' do
          launch_user_id = SecureRandom.uuid
          launch = build_stubbed(:lti_launch)
          allow(launch).to receive(:platform_user_id).and_return(launch_user_id)

          payload = described_class.new(launch: launch).payload

          expect(payload[:platform_user_id]).to eq(launch_user_id)
        end

        it 'has a nil platform_user_id if no launch is specified' do
          payload = described_class.new({}).payload

          expect(payload[:platform_user_id]).to be_nil
        end

        it 'extracts section_guid from the section if one is specified' do
          section = build_stubbed(:section)
          payload = described_class.new(section: section).payload

          expect(payload[:section_guid]).to eq(section.guid)
        end

        it 'extracts section_guid from the section associated with the ' \
           'specified context_link if no section is specified' do
          section = create(:section)
          context_link = create(:lti_context_link, section: section)

          payload = described_class.new(context_link: context_link).payload

          expect(payload[:section_guid]).to eq(section.guid)
        end

        it 'has a nil section_guid if no section or context_link are ' \
           'specified' do
          payload = described_class.new({}).payload

          expect(payload[:section_guid]).to be_nil
        end

        it 'extracts user_guid from the user if one is specified' do
          user = build_stubbed(:user)
          payload = described_class.new(user: user).payload

          expect(payload[:user_guid]).to eq(user.guid)
        end

        it 'extracts user_guid from the user associated with the ' \
           'specified user_link if no user is specified' do
          user = create(:user)
          user_link = create(:lti_user_link, user: user)

          payload = described_class.new(user_link: user_link).payload

          expect(payload[:user_guid]).to eq(user.guid)
        end

        it 'has a nil user_guid if no user or user_link are ' \
           'specified' do
          payload = described_class.new({}).payload

          expect(payload[:user_guid]).to be_nil
        end
      end

      context 'when a context link is specified,' do
        let(:program) { create(:program) }
        let(:course) { create(:course, program: program) }
        let(:section) { create(:section, course: course) }
        let(:context_link) { create(:lti_context_link, section: section) }
        let(:payload) { described_class.new(context_link: context_link).payload }

        it 'contains the context id, title, label, and context_link ' \
           'deployment_id and guid' do
          expect(payload[:context_link]).to eq(
            context_id: context_link.context_id,
            context_label: context_link.context_label,
            context_title: context_link.context_title,
            deployment_id: context_link.deployment_id,
            guid: context_link.guid
          )
        end

        it 'contains the issuer_id, guid, and name of the platform for ' \
           'the context link if no platform was specified' do
          platform = context_link.lti_platform

          expect(payload[:platform]).to eq(
            guid: platform.guid,
            issuer_id: platform.issuer_id,
            name: platform.name
          )
        end

        it 'contains the course guid, program id, and guid and name of the ' \
           'section for the context link if no section was specified' do
          expect(payload[:section]).to eq(
            course_guid: course.guid,
            guid: section.guid,
            name: section.name,
            program_id: program.id
          )
        end
      end

      context 'when a launch is specified,' do
        let(:platform) { create(:lti_platform) }
        let(:launch) { create(:lti_launch, platform:) }
        let(:payload) { described_class.new(launch: launch).payload }

        it 'contains the guid of the lti launch' do
          expect(payload[:launch]).to eq(guid: launch.guid)
        end

        it 'contains the issuer_id, guid, and name of the platform for ' \
           'the launch if no platform was specified' do
          expect(payload[:platform]).to eq(
            guid: platform.guid,
            issuer_id: platform.issuer_id,
            name: platform.name
          )
        end
      end

      context 'when params are specified,' do
        it 'contains the specified params' do
          params = { a: 1, b: 2 }
          payload = described_class.new(params: params).payload

          expect(payload[:params]).to eq(params)
        end
      end

      context 'when a platform is specified,' do
        let(:platform) { create(:lti_platform) }
        let(:payload) { described_class.new(platform: platform).payload }

        it 'contains the issuer_id, guid, and name of the platform' do
          expect(payload[:platform]).to eq(
            guid: platform.guid,
            issuer_id: platform.issuer_id,
            name: platform.name
          )
        end
      end

      context 'when a section is specified,' do
        let(:program) { create(:program) }
        let(:course) { create(:course, program: program) }
        let(:section) { create(:section, course: course) }

        let(:payload) { described_class.new(section: section).payload }

        it 'contains the course guid, program id, and guid and name of the ' \
           'specified section' do
          expect(payload[:section]).to eq(
            course_guid: course.guid,
            guid: section.guid,
            name: section.name,
            program_id: program.id
          )
        end

        it 'does not error if the section has an archived course' do
          allow(section).to receive(:course).and_return(nil)

          expect(payload[:section]).to eq(
            course_guid: nil,
            guid: section.guid,
            name: section.name,
            program_id: nil
          )
        end
      end

      context 'when session is specified,' do
        it 'contains the specified session' do
          session = { a: 1, b: 2 }
          payload = described_class.new(session: session).payload

          expect(payload[:session]).to eq(session)
        end
      end

      context 'when a user is specified,' do
        let(:user) { create(:student) }
        let(:payload) { described_class.new(user: user).payload }

        it 'contains the account type and guid of the specified user' do
          expect(payload[:user]).to eq(
            account_type: 'Student',
            guid: user.guid
          )
        end
      end

      context 'when a user link is specified,' do
        let(:user) { create(:student) }
        let(:user_link) { create(:lti_user_link, user: user) }
        let(:payload) { described_class.new(user_link: user_link).payload }

        it 'contains the platform_user_id and guid of the specified user link' do
          expect(payload[:user_link]).to eq(
            guid: user_link.guid,
            platform_user_id: user_link.platform_user_id
          )
        end

        it 'contains the account type and guid of the user for the ' \
           'specified user link if no user was specified' do
          expect(payload[:user]).to eq(
            account_type: 'Student',
            guid: user.guid
          )
        end
      end
    end
  end
end
