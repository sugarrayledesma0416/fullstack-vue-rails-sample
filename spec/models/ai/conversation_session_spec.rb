describe AI::ConversationSession do
  describe '.create_preview' do
    let(:user) { create(:user) }
    let(:preview_activity) { create(:activity, activity_type: 'ai_virtual_chat') }
    let(:question) do
      instance_double('Question', initial_prompt: 'Initial prompt', system_prompt: 'System prompt')
    end
    let(:content_object) { instance_double('ContentObject', question:) }
    let(:activity_extractor) { instance_double('AI::ActivityExtractor') }
    let(:references_formatter) { instance_double('AI::ActivityReferencesFormatter') }

    before do
      allow(preview_activity).to receive(:content_object).and_return(content_object)
      allow(AI::ActivityExtractor).to receive(:new).with(preview_activity).and_return(activity_extractor)
      allow(AI::ActivityReferencesFormatter).to receive(:new).with(activity_extractor).and_return(references_formatter)
    end

    context 'when activity has refrerences' do
      before do
        allow(activity_extractor).to receive(:reference_data).and_return({ 'some' => 'data' })
        allow(references_formatter).to receive(:format_as_xml).and_return('<references>XML</references>')
      end

      it 'creates a session with references in the system prompt' do
        session = described_class.create_preview(preview_activity, user)

        expect(session).to be_persisted
        expect(session.preview_system_prompt).to eq('System prompt')
        expect(session.messages.count).to eq(1)
        expect(session.messages.first.message_text).to eq('Initial prompt')
      end
    end

    context 'when activity has no references' do
      before do
        allow(activity_extractor).to receive(:reference_data).and_return({})
        allow(references_formatter).to receive(:format_as_xml).and_return('<references></references>')
      end

      it 'creates a session with just the system prompt' do
        session = described_class.create_preview(preview_activity, user)

        expect(session).to be_persisted
        expect(session.preview_system_prompt).to eq('System prompt')
        expect(session.messages.count).to eq(1)
        expect(session.messages.first.message_text).to eq('Initial prompt')
      end
    end

    it 'creates a session with the correct attributes' do
      session = described_class.create_preview(preview_activity, user)

      expect(session).to be_persisted
      expect(session.user).to eq(user)
      expect(session.activity).to be_nil
      expect(session.preview_system_prompt).to eq('System prompt')
    end

    it 'creates an initial message for the session' do
      session = described_class.create_preview(preview_activity, user)

      expect(session.messages.count).to eq(1)
      message = session.messages.first
      expect(message.message_text).to eq('Initial prompt')
      expect(message.role).to eq('assistant')
    end
  end

  describe '#create_initial_message' do
    let(:user) { create(:user) }
    let(:activity) { create(:activity) }
    let(:question) do
      instance_double('Question', initial_prompt: 'Initial prompt', system_prompt: 'System prompt')
    end
    let(:content_object) { instance_double('ContentObject', question:) }
    let(:activity_extractor) { instance_double('AI::ActivityExtractor') }
    let(:references_formatter) { instance_double('AI::ActivityReferencesFormatter') }
    let(:session) { create(:ai_conversation_session, user: user, activity: activity) }

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(AI::ActivityExtractor).to receive(:new).with(activity).and_return(activity_extractor)
      allow(AI::ActivityReferencesFormatter).to receive(:new).with(activity_extractor).and_return(references_formatter)
    end

    context 'when activity has references' do
      before do
        allow(activity_extractor).to receive(:reference_data).and_return({ 'some' => 'data' })
        allow(references_formatter).to receive(:format_as_xml).and_return('<references>XML</references>')
      end

      it 'creates a message with references' do
        session.create_initial_message

        expect(session.messages.count).to eq(1)
        expect(session.messages.first.message_text).to eq('Initial prompt')
      end
    end

    context 'when activity has no references' do
      before do
        allow(activity_extractor).to receive(:reference_data).and_return({})
        allow(references_formatter).to receive(:format_as_xml).and_return('<references></references>')
      end

      it 'creates a message with empty references' do
        session.create_initial_message

        expect(session.messages.count).to eq(1)
        expect(session.messages.first.message_text).to eq('Initial prompt')
      end
    end

    context 'when messages already exist' do
      before do
        create(:ai_conversation_session_message, session: session)
      end

      it 'does not create new messages' do
        expect { session.create_initial_message }.not_to change { session.messages.count }
      end
    end
  end

  describe '#log_response_failure' do
    let(:conversation_session) { create(:ai_conversation_session) }

    before do
      allow(VHLMonitor).to receive(:notify)
    end

    context 'when an exception is specified' do
      let(:error) { RuntimeError.new('foo') }

      before do
        conversation_session.log_response_failure(error)
      end

      it 'notifies VHLMonitor of the error' do
        expect(VHLMonitor).to have_received(:notify).with(error)
      end

      it 'updates the completion_failure_reason with the failure message' do
        expect(conversation_session.reload).to have_attributes(
          completion_failure_reason: described_class::FAILURE_REASON_MESSAGE
        )
      end
    end

    context 'when a string is specified' do
      before do
        conversation_session.log_response_failure('error_text')
      end

      it 'does not notify VHLMonitor of the error' do
        expect(VHLMonitor).not_to have_received(:notify)
      end

      it 'updates the completion_failure_reason with the specified message' do
        expect(conversation_session.reload).to have_attributes(
          completion_failure_reason: 'error_text'
        )
      end
    end
  end

  describe '#restart' do
    let(:attempt) { create(:attempt) }
    let(:session) do
      create(
        :ai_conversation_session,
        activity_id: attempt.activity_id,
        attempt:
      )
    end

    let!(:first_assistant_message) do
      create(
        :ai_conversation_session_message,
        audio_file_path: 'foo1.wav',
        session:,
        role: 'assistant'
      )
    end

    before do
      create(
        :ai_conversation_session_message,
        audio_file_path: 'foo2.wav',
        session:,
        role: 'user'
      )

      create(
        :ai_conversation_session_message,
        audio_file_path: 'foo3.wav',
        session:,
        role: 'assistant'
      )

      create(
        :ai_conversation_session_message,
        audio_file_path: 'foo4.wav',
        session:,
        role: 'user'
      )

      allow(AI::ConversationMessageDeleterWorker).to receive(:perform_async)
    end

    it 'deletes all messages except the first assistant message' do
      session.restart

      expect(session.messages.reload).to contain_exactly(
        first_assistant_message
      )
    end

    it 'enqueues a ConversationMessageDeleterWorker with the audio paths ' \
       'of the deleted messages' do
      session.restart

      expect(AI::ConversationMessageDeleterWorker).to have_received(:perform_async).with(
        ['foo2.wav', 'foo3.wav', 'foo4.wav']
      )
    end
  end

  describe '#saved_messages' do
    let(:attempt) { create(:attempt) }
    let(:session) do
      create(
        :ai_conversation_session,
        activity_id: attempt.activity_id,
        attempt:
      )
    end

    it 'returns all the messages sorted by created_at' do
      assistant_message = create(
        :ai_conversation_session_message,
        role: 'assistant',
        session:
      )
      user_message = create(
        :ai_conversation_session_message,
        message_text: 'b',
        role: 'user',
        session:
      )

      # rubocop:disable Rails/SkipsModelValidations
      user_message.update_column(
        :created_at, assistant_message.created_at - 1.minute
      )
      # rubocop:enable Rails/SkipsModelValidations

      expect(session.saved_messages).to eq(
        [user_message, assistant_message]
      )
    end
  end

  describe '#find_or_create_message' do
    let(:session) { create(:ai_conversation_session) }

    context 'when a message already exists with that guid in that session,' do
      let!(:message) { create(:ai_conversation_session_message, session:) }

      it 'returns the existing message based on the guid' do
        expect(
          session.find_or_create_message(
            guid: message.guid,
            role: 'assistant',
            audio_file_path: 'different/path',
            message_text: 'different message'
          )
        ).to eq(message)
      end

      it 'does not update the existing message' do
        expect do
          session.find_or_create_message(
            guid: message.guid,
            role: 'assistant',
            audio_file_path: 'different/path',
            message_text: 'different message'
          )
        end.to not_change { message.reload.attributes }
      end
    end

    context 'when a message already exists with that guid in a different session,' do
      let!(:message) { create(:ai_conversation_session_message) }
      let(:message_attrs) do
        {
          audio_file_path: 'some/path',
          guid: message.guid,
          message_text: 'some message',
          role: 'user'
        }
      end

      it 'creates a new message' do
        expect do
          session.find_or_create_message(**message_attrs)
        end.to change(AI::ConversationSessionMessage, :count).by(1)
      end

      it 'returns the new message' do
        expect(session.find_or_create_message(**message_attrs)).to eq(
          AI::ConversationSessionMessage.last
        )
      end

      it 'sets the new message attributes,' do
        session.find_or_create_message(**message_attrs)

        expect(AI::ConversationSessionMessage.last).to have_attributes(
          message_attrs.merge(session_id: session.id)
        )
      end

      it 'raises an error when some attributes are invalid,' do
        expect do
          session.find_or_create_message(**message_attrs.merge(role: 'invalid role'))
        end.to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: Role must be included in the list'
        )
      end
    end

    context 'when the message does not exist,' do
      let(:message_attrs) do
        {
          audio_file_path: 'some/path',
          guid: SecureRandom.uuid,
          message_text: 'some message',
          role: 'user',
        }
      end

      it 'creates a new message' do
        expect do
          session.find_or_create_message(**message_attrs)
        end.to change(AI::ConversationSessionMessage, :count).by(1)
      end

      it 'returns the new message' do
        expect(session.find_or_create_message(**message_attrs)).to eq(
          AI::ConversationSessionMessage.last
        )
      end

      it 'sets the new message attributes,' do
        session.find_or_create_message(**message_attrs)

        expect(AI::ConversationSessionMessage.last).to have_attributes(
          message_attrs.merge(session_id: session.id)
        )
      end

      it 'raises an error when some attributes are invalid,' do
        expect do
          session.find_or_create_message(**message_attrs.merge(role: 'invalid role'))
        end.to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: Role must be included in the list'
        )
      end
    end
  end


  describe '#conversation_status' do
    let(:user) { create(:user) }
    let(:activity) { create(:activity) }
    let(:session) { create(:ai_conversation_session, user: user, activity: activity) }

    context 'when no messages exist' do
      it 'returns incomplete when no messages exist' do
        content = { 'on_topic' => true, 'expected_response_count' => 3 }
        expect(session.send(:conversation_status, content)).to eq('incomplete')
      end
    end

    context 'with existing messages' do
      let!(:message1) do
        create(:ai_conversation_session_message,
          session: session,
          role: 'user',
          ai_api_response: { 'content' => { 'on_topic' => true }.to_json }
        )
      end

      let!(:message2) do
        create(:ai_conversation_session_message,
          session: session,
          role: 'assistant',
          ai_api_response: { 'content' => { 'on_topic' => true }.to_json }
        )
      end

      it 'returns complete when on_topic count meets expected_response_count' do
        content = { 'on_topic' => false, 'expected_response_count' => 2 }
        expect(session.send(:conversation_status, content)).to eq('complete')
      end

      it 'returns complete when on_topic count is greater than expected_response_count' do
        content = { 'on_topic' => false, 'expected_response_count' => 2 }
        expect(session.send(:conversation_status, content)).to eq('complete')
      end
      
      it 'returns incomplete when on_topic count is less than expected_response_count' do
        content = { 'on_topic' => false, 'expected_response_count' => 3 }
        expect(session.send(:conversation_status, content)).to eq('incomplete')
      end

      it 'returns complete  when on_topic count is equal expected_response_count' do
        content = { 'on_topic' => true, 'expected_response_count' => 3 }
        expect(session.send(:conversation_status, content)).to eq('complete')
      end
      
      it 'uses default expected_response_count when not provided' do
        content = { 'on_topic' => false }
        expect(session.send(:conversation_status, content)).to eq('incomplete')
      end
      
      it 'counts only on_topic messages' do
        create(:ai_conversation_session_message, 
          session: session, 
          role: 'user',
          ai_api_response: { 'content' => { 'on_topic' => false }.to_json }
        )
        
        content = { 'on_topic' => true, 'expected_response_count' => 2 }
        expect(session.send(:conversation_status, content)).to eq('complete')
      end
      
      it 'handles messages with invalid JSON gracefully' do
        create(:ai_conversation_session_message, 
          session: session, 
          role: 'user',
          ai_api_response: { 'content' => 'invalid json' }
        )
        
        content = { 'on_topic' => true, 'expected_response_count' => 2 }
        expect(session.send(:conversation_status, content)).to eq('complete')
      end
    end
  end

  describe '#references_message' do
    let(:session) { create(:ai_conversation_session) }
    let(:activity) { create(:activity) }
    let(:references_formatter) { instance_double('AI::ActivityReferencesFormatter') }

    before do
      allow(session).to receive(:activity).and_return(activity)
      allow(AI::ActivityReferencesFormatter).to receive(:new).with(activity).and_return(references_formatter)
    end

    context 'when activity has references' do
      before do
        allow(references_formatter).to receive(:format_as_xml).and_return('<references>XML</references>')
      end

      it 'returns a message with the formatted references' do
        message = session.send(:references_message)
        expect(message.message_text).to eq('<references>XML</references>')
        expect(message.role).to eq('assistant')
      end
    end

    context 'when activity has no references' do
      before do
        allow(references_formatter).to receive(:format_as_xml).and_return(nil)
      end

      it 'returns a message with empty references' do
        message = session.send(:references_message)
        expect(message.message_text).to eq('<references></references>')
        expect(message.role).to eq('assistant')
      end
    end
  end

  describe '#get_response' do
    let(:user) { create(:user) }
    let(:session) { create(:ai_conversation_session, user:) }
    let(:client) { instance_double(VHL::AI::Core::Client) }
    let(:guid) { SecureRandom.uuid }
    let(:message_text) { 'Hello' }
    let(:ai_response) do
      instance_double('VHL::AI::Core::Response',
        to_api_hash: {
          'content' => {
            'partner_response' => 'Hi there!',
            'status' => 'incomplete',
            'on_topic' => true
          }.to_json
        },
        partner_response: 'Hi there!'
      )
    end
    let(:question) { instance_double('Question', initial_prompt: 'Initial prompt', system_prompt: 'System prompt') }
    let(:content_object) { instance_double('ContentObject', question: question) }

    before do
      allow(VHL::AI::Core::Client).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return(ai_response)
      allow(session.activity).to receive(:content_object).and_return(content_object)
      allow(content_object).to receive(:references).and_return([])
    end

    it 'passes the correct span attributes to the AI client' do
      session.get_response(guid:, message_text:)

      expect(client).to have_received(:chat).with(
        {
          parameters: {
            messages: [
              {"content"=>"System prompt", "role"=>"system"},
              {"content"=>"<references></references>", "role"=>"assistant"},
              {"content"=>"Hello", "role"=>"user"}
            ],
            model: 'gpt-4o-2024-08-06',
            response_format: session.send(:response_format),
            temperature: 0.6
          },
          response_schema_type: :virtual_chat,
          span_attributes: {
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => user&.id,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => session&.id,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'ai_virtual_chat',
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_VERSION => VHL::AI::Core::VERSION
          }
        }
      )
    end

    it 'creates a new message with the AI response' do
      expect do
        session.get_response(guid:, message_text:)
      end.to change(AI::ConversationSessionMessage, :count).by(2)

      user_message = session.messages.find_by(guid:)
      expect(user_message).to have_attributes(
        role: 'user',
        message_text: message_text
      )

      assistant_message = session.messages.where(role: 'assistant').where.not(guid: nil).last
      expect(assistant_message).to have_attributes(
        role: 'assistant',
        message_text: 'Hi there!'
      )
    end
  end
end
