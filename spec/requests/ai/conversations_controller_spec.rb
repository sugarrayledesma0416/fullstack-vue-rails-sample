require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe AI::ConversationsController do
  include RspecJsContentHelpers

  def serialized_message(message)
    {
      'audio_file_path' => message.audio_file_path,
      'guid' => message.guid,
      'message_text' => message.message_text,
      'role' => message.role,
      'status' => nil,
      'on_topic' => nil
    }
  end

  describe 'POST session_response' do
    let(:program) { create(:program_with_lessons) }

    let(:vhl_core_client) { instance_double(VHL::AI::Core::Client) }

    let(:activity) do
      create_activity_with_content(
        File.join('spec', 'fixtures', 'xml', 'ai_virtual_chat_with_references.xml'),
        program,
        grading_method: 'instructor'
      )
    end

    let(:attempt) { create(:attempt, activity:) }
    let(:conversation_session) { attempt.find_or_create_ai_virtual_chat_session }
    let(:user_message_text) { 'abc' }
    let(:user_message_guid) { SecureRandom.uuid }

    before do
      allow(VHL::AI::Core::Client).to receive(:new).and_return(vhl_core_client)
      allow(vhl_core_client).to receive(:chat).and_return(
        VHL::AI::Schemas::OpenAI::Response::VirtualChatSchema.new(
          partner_response: 'How are you?',
          status: 'incomplete',
          on_topic: true,
          role: 'assistant',
          expected_response_count: 3
        )
      )
    end

    def target_url
      session_response_ai_conversation_path(id: conversation_session.id)
    end

    def do_request(extra_params = {})
      default_params = { message: { message_text: user_message_text, guid: user_message_guid } }
      post(target_url, params: default_params.merge(extra_params))
    end

    include_examples 'require logged in user'

    context 'with a logged-in user,' do
      let(:user) { create(:user) }

      before do
        log_in_user(user)
      end

      it 'finds the session with the specified id, adds a the specified ' \
         'user message and the ai response, and returns the ai response' do
        do_request

        expect(response).to be_ok

        messages = conversation_session.reload.messages

        expect(messages[1]).to have_attributes(
          message_text: user_message_text,
          guid: user_message_guid,
          role: 'user'
        )

        expect(messages[2]).to have_attributes(
          message_text: 'How are you?',
          role: 'assistant'
        )

        expect(response.parsed_body.symbolize_keys).to eq(
          message: serialized_message(messages[2]).merge(
            'status' => 'incomplete',
            'on_topic' => true
          )
        )
      end

      it 'logs any failure to fetch an ai response in the session record' do
        allow(vhl_core_client).to receive(:chat).and_raise('error_msg')

        do_request

        expect(conversation_session.reload).to have_attributes(
          completion_failure_reason: AI::ConversationSession::FAILURE_REASON_MESSAGE
        )
      end
    end
  end

  describe 'GET saved_messages' do
    let(:student) { create(:student) }
    let(:attempt) { create(:attempt, section_id: 0, user: student) }
    let(:conversation_session) do
      create(
        :ai_conversation_session,
        activity_id: attempt.activity_id,
        attempt:,
        user_id: attempt.user_id
      )
    end
    let!(:assistant_message) do
      create(
        :ai_conversation_session_message,
        session: conversation_session,
        role: 'assistant'
      )
    end
    let!(:user_message) do
      create(
        :ai_conversation_session_message,
        session: conversation_session,
        role: 'user'
      )
    end

    def do_request
      get(saved_messages_ai_conversation_path(id: conversation_session.id))
    end

    include_examples 'require logged in user'

    context 'with a logged-in student,' do
      before do
        log_in_user(student)
      end

      it 'renders json with the assistant and user messages from the session ' \
         'when the specified session was recorded by the logged-in student' do
        do_request

        expect(response).to be_ok

        expect(response.parsed_body.symbolize_keys).to eq(
          messages: [
            serialized_message(assistant_message),
            serialized_message(user_message)
          ]
        )
      end

      it 'renders an error message with an unauthorized status when the ' \
         'specified session was recorded by a student other than the ' \
         'logged-in student' do
        conversation_session.update!(user_id: create(:student).id)

        do_request

        expect(response).to be_unauthorized

        expect(response.parsed_body.symbolize_keys).to eq(
          error: 'not-authorized', messages: []
        )
      end
    end

    context 'with a logged-in instructor,' do
      let(:instructor) { create(:instructor) }

      before do
        log_in_user(instructor)
      end

      it 'renders json with the assistant and user messages from the session ' \
         'when the specified session was recorded by the logged-in instructor' do
        conversation_session.update!(user_id: instructor.id)

        do_request

        expect(response).to be_ok

        expect(response.parsed_body.symbolize_keys).to eq(
          messages: [
            serialized_message(assistant_message),
            serialized_message(user_message)
          ]
        )
      end

      it 'renders an error message with an unauthorized status when the ' \
         'specified session was recorded by an instructor other than the ' \
         'logged-in instructor' do
        conversation_session.update!(user_id: create(:instructor).id)

        do_request

        expect(response).to be_unauthorized

        expect(response.parsed_body.symbolize_keys).to eq(
          error: 'not-authorized', messages: []
        )
      end

      it 'renders an error message with an unauthorized status when the ' \
         'specified session was recorded by a student not enrolled in a ' \
         'course' do
        do_request

        expect(response).to be_unauthorized

        expect(response.parsed_body.symbolize_keys).to eq(
          error: 'not-authorized', messages: []
        )
      end

      it 'renders an error message with an unauthorized status when the ' \
         'specified session has no associated attempt, belongs to section ' \
         'zero and is not recorded by the currently logged-in instructor' do
        conversation_session.update!(attempt_id: nil)

        do_request

        expect(response).to be_unauthorized

        expect(response.parsed_body.symbolize_keys).to eq(
          error: 'not-authorized', messages: []
        )
      end

      it 'renders an error message with an unauthorized status when the ' \
         'specified session belongs to a section for which the logged-in ' \
         'instructor is not an owner or co-instructor' do
        attempt.update!(section_id: create(:section).id)

        do_request

        expect(response).to be_unauthorized

        expect(response.parsed_body.symbolize_keys).to eq(
          error: 'not-authorized', messages: []
        )
      end

      it 'renders json with the assistant and user messages from the session ' \
         'when the specified session belongs to a section owned by the logged-in ' \
         'instructor' do
        course = create(:course, owner: instructor)
        section = create(:section, course:, instructor:)
        attempt.update!(section_id: section.id)

        do_request

        expect(response).to be_ok

        expect(response.parsed_body.symbolize_keys).to eq(
          messages: [
            serialized_message(assistant_message),
            serialized_message(user_message)
          ]
        )
      end

      it 'renders json with the assistant and user messages from the session ' \
         'when the specified session belongs to a section for which the logged-in ' \
         'instructor is a co-instructor' do
        section = create(:section)
        create(:section_co_instructor, instructor:, section:)
        attempt.update!(section_id: section.id)

        do_request

        expect(response).to be_ok

        expect(response.parsed_body.symbolize_keys).to eq(
          messages: [
            serialized_message(assistant_message),
            serialized_message(user_message)
          ]
        )
      end
    end
  end

  describe 'PATCH restart_session' do
    let(:user) { create(:user) }
    let(:attempt) { create(:attempt, section_id: 0, user:) }

    let(:conversation_session) do
      create(
        :ai_conversation_session,
        attempt:,
        user_id: attempt.user_id,
        activity_id: attempt.activity_id
      )
    end

    let!(:initial_assistant_message) do
      create(
        :ai_conversation_session_message,
        session: conversation_session,
        role: 'assistant'
      )
    end

    let!(:user_message) do
      create(
        :ai_conversation_session_message,
        session: conversation_session,
        role: 'user'
      )
    end

    let!(:second_assistant_message) do
      create(
        :ai_conversation_session_message,
        session: conversation_session,
        role: 'assistant'
      )
    end

    def do_request
      patch(
        restart_session_ai_conversation_path(id: conversation_session.id)
      )
    end

    include_examples 'require logged in user'

    context 'with a logged-in user,' do
      before do
        log_in_user(user)
      end

      it 'does not reset the messages for the specified session id if ' \
         'the logged-in user is not the user of the session' do
        conversation_session.update!(user_id: create(:user).id)

        do_request

        expect(response).to be_unauthorized

        expect(response.parsed_body.symbolize_keys).to eq(
          error: 'not-authorized'
        )

        expect(conversation_session.messages.reload).to contain_exactly(
          initial_assistant_message, user_message, second_assistant_message
        )
      end

      # TODO: Handle practice mode, with no attempt record.

      it 'resets the messages for the specified session id if ' \
         'the user of the session is the logged-in user' do
        do_request

        expect(response).to be_ok

        expect(conversation_session.messages.reload).to contain_exactly(
          initial_assistant_message
        )
      end
    end
  end

  describe 'PATCH update_messages' do
    let(:student) { create(:student) }
    let(:attempt) { create(:attempt, section_id: 0, user: student) }
    let(:conversation_session) do
      create(
        :ai_conversation_session,
        attempt:,
        user_id: attempt.user_id,
        activity_id: attempt.activity_id
      )
    end

    let!(:assistant_message) do
      create(
        :ai_conversation_session_message,
        session: conversation_session,
        role: 'assistant'
      )
    end

    let!(:user_message) do
      create(
        :ai_conversation_session_message,
        session: conversation_session,
        role: 'user'
      )
    end

    def do_request
      default_params = { messages: [ { guid: user_message.guid, audio_file_path: '/some/path' } ] }
      patch(
        update_messages_ai_conversation_path(id: conversation_session.id),
        params: default_params
      )
    end

    include_examples 'require logged in user'

    context 'with a logged-in student,' do
      before do
        log_in_user(student)
      end

      it 'updates the messages and renders json with the assistant and ' \
         'user messages from the session when the specified session was recorded ' \
         'by the logged-in student' do
           # TODO: How to test that an efficient way?
        updater = instance_double(AI::ConversationSessionMessagesUpdater, update: true)
        allow(AI::ConversationSessionMessagesUpdater).to receive(:new)
          .with(
            session: conversation_session,
            messages_attrs: a_collection_containing_exactly(
              {
                'guid' => user_message.guid,
                'audio_file_path' => '/some/path'
              }
            )
          ).and_return(updater)

        do_request

        expect(response).to be_ok

        expect(updater).to have_received(:update)
        expect(response.parsed_body.symbolize_keys).to eq(
          messages: [
            serialized_message(assistant_message.reload),
            serialized_message(user_message.reload)
          ]
        )
      end

      it 'does not update the messages and renders an error message with an ' \
         'unauthorized status when the specified session was recorded by a ' \
         'student other than the logged-in student' do
        conversation_session.update!(user_id: create(:student).id)

        do_request

        expect(response).to be_unauthorized

        expect(response.parsed_body.symbolize_keys).to eq(
          error: 'not-authorized'
        )
      end
    end

    context 'with a logged-in instructor,' do
      let(:instructor) { create(:instructor) }

      before do
        log_in_user(instructor)
      end

      it 'renders json with the assistant and user messages from the session ' \
         'when the specified session was recorded by the logged-in instructor' do
        conversation_session.update!(user_id: instructor.id)

        do_request

        expect(response).to be_ok

        expect(response.parsed_body.symbolize_keys).to eq(
          messages: [
            serialized_message(assistant_message.reload),
            serialized_message(user_message.reload)
          ]
        )
      end

      it 'renders an error message with an unauthorized status when the ' \
         'specified session was recorded by an instructor other than the ' \
         'logged-in instructor' do
        conversation_session.update!(user_id: create(:instructor).id)

        do_request

        expect(response).to be_unauthorized

        expect(response.parsed_body.symbolize_keys).to eq(
          error: 'not-authorized'
        )
      end
    end
  end
end
