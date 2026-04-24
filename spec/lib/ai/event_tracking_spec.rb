describe AI::EventTracking do
  describe '#with_ai_grading_event_tracking' do
    let(:event_class) { described_class::Event }
    let(:payload) { { a: 1, b: 2 } }
    let(:event) { instance_double(event_class, payload:) }
    let(:message) { 'my message' }
    let(:test_class) do
      Class.new do
        include AI::EventTracking
      end
    end

    before do
      allow(event_class).to receive(:new).and_return(event)
      allow(STATS_PROXY).to receive(:info)
    end

    context 'when no errors are raised,' do
      it 'dispatches the specified message and event payload when called' \
         'without a block' do
        test_class.new.with_ai_grading_event_tracking(message)

        expect(STATS_PROXY).to have_received(:info).with(
          hash_including(
            {
              application: :m3,
              environment: 'test',
              event_action: message,
              vhl_component: :ai_grading
            }.merge(payload)
          )
        )
      end

      it 'dispatches the specified message and event payload' do
        test_class.new.with_ai_grading_event_tracking(message) do
          _somevar = 1
        end

        expect(STATS_PROXY).to have_received(:info).with(
          hash_including(
            {
              application: :m3,
              environment: 'test',
              event_action: message,
              vhl_component: :ai_grading
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
          test_class.new.with_ai_grading_event_tracking(message) do
            _somevar = 1
          end
        rescue StandardError => e
          # ignore the re-raised error if it is the expected error
          raise e unless e.message == error_message
        end

        expect(STATS_PROXY).to have_received(:info).with(
          hash_including(
            error_class: StandardError,
            error_message:,
            error_location: /and_raise/
          )
        )
      end

      it 're-raises the error after capturing the error information' do
        expect do
          test_class.new.with_ai_grading_event_tracking(message) do
            _somevar = 1
          end
        end.to raise_error(StandardError, error_message)
      end
    end

    context 'when an error is raised when yielding to the specified block' do
      let(:error_message) { 'Something worse happened' }

      it 'dispatches information about the error' do
        begin
          test_class.new.with_ai_grading_event_tracking(message) do
            raise StandardError, error_message
          end
        rescue StandardError => e
          # ignore the re-raised error if it is the expected error
          raise e unless e.message == error_message
        end

        expect(STATS_PROXY).to have_received(:info).with(
          hash_including(
            error_class: StandardError,
            error_message:,
            error_location: /#{__FILE__}/
          )
        )
      end

      it 're-raises the error after capturing the error information' do
        expect do
          test_class.new.with_ai_grading_event_tracking(message) do
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
          extra: {},
          params: {},
          section: {},
          section_guid: nil,
          session: {},
          user: {},
          user_guid: nil
        )
      end

      describe 'critical index data' do
        it 'extracts section_guid from the section if one is specified' do
          section = build_stubbed(:section)
          payload = described_class.new(section:).payload

          expect(payload[:section_guid]).to eq(section.guid)
        end

        it 'has a nil section_guid if no section is specified' do
          payload = described_class.new({}).payload

          expect(payload[:section_guid]).to be_nil
        end

        it 'extracts user_guid from the user if one is specified' do
          user = build_stubbed(:user)
          payload = described_class.new(user:).payload

          expect(payload[:user_guid]).to eq(user.guid)
        end

        it 'has a nil user_guid if no user is specified' do
          payload = described_class.new({}).payload

          expect(payload[:user_guid]).to be_nil
        end
      end

      context 'when params are specified,' do
        it 'contains the specified params' do
          params = { a: 1, b: 2 }
          payload = described_class.new(params:).payload

          expect(payload[:params]).to eq(params)
        end
      end

      context 'when a section is specified,' do
        let(:program) { create(:program) }
        let(:course) { create(:course, program:) }
        let(:section) { create(:section, course:) }

        let(:payload) { described_class.new(section:).payload }

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
          payload = described_class.new(session:).payload

          expect(payload[:session]).to eq(session)
        end
      end

      context 'when a user is specified,' do
        let(:user) { create(:instructor) }
        let(:payload) { described_class.new(user:).payload }

        it 'contains the account type and guid of the specified user' do
          expect(payload[:user]).to eq(
            account_type: 'Instructor',
            guid: user.guid
          )
        end
      end
    end
  end
end
