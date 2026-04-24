require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe VideoChatController do
  # Even though these are functional tests, these wrapper must be mocked
  # to avoid making real api calls across the wire to TokBox api or
  # DynamoDb.
  let(:tokbox_wrapper) { instance_double(VideoChat::TokBoxWrapper) }
  let(:dynamo_wrapper) { instance_double(DynamoWrapper, put: true, errors?: false) }
  let(:recording_id) { SecureRandom.uuid }
  let(:tokbox_recording) { { id: recording_id } }

  before do
    allow(VideoChat::TokBoxWrapper).to receive(:new).and_return(tokbox_wrapper)
    allow(DynamoWrapper).to receive(:new).and_return(dynamo_wrapper)
    allow(tokbox_wrapper).to receive(:record).and_return(tokbox_recording)
  end

  describe 'POST /create_session' do
    let(:user) { create(:student) }
    let(:tokbox_session) { SecureRandom.uuid }

    def do_request
      post(video_chat_sessions_path)
    end

    include_examples 'require logged in user'

    before do
      allow(tokbox_wrapper).to receive(:get_session).and_return(tokbox_session)
    end

    context 'with a logged in user,' do
      before { log_in_user(user) }

      it 'retrieves a video session id from the tokbox API' do
        allow(tokbox_wrapper).to receive(:errors?).and_return(false)

        do_request

        expect(tokbox_wrapper).to have_received(:get_session)
        expect(response).to be_ok
        expect(response.body).to eq tokbox_session
      end

      it 'returns errors if something happened' do
        errors = %w[error_1 error_2 error_3]

        allow(tokbox_wrapper).to receive(:errors?).and_return(true)
        allow(tokbox_wrapper).to receive(:errors).and_return(errors)

        do_request

        expect(response).to be_forbidden
        expect(JSON.parse(response.body, symbolize_names: true)).to eq(video_chat: errors)
      end
    end
  end

  describe 'POST /start_recording' do
    let(:user) { create(:student) }
    let(:session_id) { SecureRandom.uuid }
    let(:target_path) do
      video_chat_recording_path(session_id: session_id)
    end
    let(:school) { create(:school) }
    let(:course) { create(:course) }
    let(:activity) { create(:activity) }
    let(:user_1) { create(:student) }
    let(:user_2) { create(:student) }
    let(:user_3) { create(:student) }
    let(:user_1_section) { create(:section, course: course) }
    let(:user_2_section) { create(:section, course: course) }
    let(:default_params) do
      {
        school_id: school.id,
        course_id: course.id,
        activity_id: activity.id,
        user_1: {
          id: user_1.id.to_s,
          section_id: "section_#{user_1_section.id}"
        },
        user_2: {
          id: user_2.id.to_s,
          section_id: "section_#{user_2_section.id}"
        }
      }
    end

    let(:group_chat_params) do
      {
        school_id: school.id,
        course_id: course.id,
        activity_id: activity.id,
        users: [
          {
            id: user_1.id.to_s,
            section_id: "section_#{user_1_section.id}"
          },
          {
            id: user_2.id.to_s,
            section_id: "section_#{user_2_section.id}"
          },
          {
            id: user_3.id.to_s,
            section_id: "section_#{user_2_section.id}"
          }
        ]
      }
    end

    let(:solo_chat_params) do
      {
        school_id: school.id,
        course_id: course.id,
        activity_id: activity.id,
        user_1: {
          id: user_1.id.to_s,
          section_id: "section_#{user_1_section.id}"
        }
      }
    end

    let(:bad_chat_params) do
      {
        school_id: school.id,
        course_id: course.id,
        activity_id: activity.id
      }
    end



    def do_request(extra_params = {})
      post(target_path, params: default_params.deep_merge(extra_params))
    end

    def do_non_pchat_request(params)
      post(target_path, params: params)
    end

    include_examples 'require logged in user'

    context 'with a logged in user,' do
      before { log_in_user(user) }

      it 'renders json with tokbox errors if the tokbox call fails' do
        errors = ['something failed']
        allow(tokbox_wrapper).to receive(:errors?).and_return(true)
        allow(tokbox_wrapper).to receive(:errors).and_return(errors)

        do_request

        expect(VideoChat::TokBoxWrapper).to have_received(:new).with(user)

        expect(tokbox_wrapper).to have_received(:record).with(session_id)

        expect(response).to be_forbidden

        expect(JSON.parse(response.body)).to eq('video_chat' => errors)
      end

      it 'renders json with dynamo errors if the dynamo call fails' do
        errors = ['something failed']
        allow(tokbox_wrapper).to receive(:errors?).and_return(false)
        allow(dynamo_wrapper).to receive(:errors?).and_return(true)
        allow(dynamo_wrapper).to receive(:error_messages).and_return(errors)

        do_request

        expect(VideoChat::TokBoxWrapper).to have_received(:new).with(user)

        expect(tokbox_wrapper).to have_received(:record).with(session_id)

        expect(response).to be_forbidden

        expect(JSON.parse(response.body)).to eq('video_chat' => errors)
      end

      it 'writes a new dynamo item and renders json with the tokbox ' \
         'recording object if the tokbox call is successful' do
        allow(tokbox_wrapper).to receive(:errors?).and_return(false)

        do_request

        expect(VideoChat::TokBoxWrapper).to have_received(:new).with(user)

        expect(tokbox_wrapper).to have_received(:record).with(session_id)

        expect(response).to be_ok

        expect(JSON.parse(response.body)).to eq('id' => recording_id)

        expect(dynamo_wrapper).to have_received(:put).with(
          new_item: {
            archive_id: recording_id,
            status: 'started',
            school_id: school.id.to_s,
            course_id: course.id.to_s,
            activity_id: activity.id.to_s,
            user_1_id: user_1.id,
            user_2_id: user_2.id,
            user_1: { id: user_1.id.to_s, section_id: user_1_section.id.to_s },
            user_2: { id: user_2.id.to_s, section_id: user_2_section.id.to_s }
          }
        )
      end

      it 'writes a new dynamo item with users info for group chats and renders json with the tokbox ' \
         'recording object if the tokbox call is successful' do
        allow(tokbox_wrapper).to receive(:errors?).and_return(false)
        do_non_pchat_request(group_chat_params)

        expect(VideoChat::TokBoxWrapper).to have_received(:new).with(user)

        expect(tokbox_wrapper).to have_received(:record).with(session_id)

        expect(response).to be_ok

        expect(JSON.parse(response.body)).to eq('id' => recording_id)

        expect(dynamo_wrapper).to have_received(:put).with(
          new_item: {
            archive_id: recording_id,
            status: 'started',
            school_id: school.id.to_s,
            course_id: course.id.to_s,
            activity_id: activity.id.to_s,
            users: [ {id: user_1.id.to_s, section_id: user_1_section.id.to_s },
                     { id: user_2.id.to_s, section_id: user_2_section.id.to_s },
                     { id: user_3.id.to_s, section_id: user_2_section.id.to_s }
            ]
          }
        )
      end

      it 'writes a new dynamo item with single user info for solo chat recording and renders json with the tokbox ' \
         'recording object if the tokbox call is successful' do
        allow(tokbox_wrapper).to receive(:errors?).and_return(false)
        do_non_pchat_request(solo_chat_params)

        expect(VideoChat::TokBoxWrapper).to have_received(:new).with(user)

        expect(tokbox_wrapper).to have_received(:record).with(session_id)

        expect(response).to be_ok

        expect(JSON.parse(response.body)).to eq('id' => recording_id)

        expect(dynamo_wrapper).to have_received(:put).with(
          new_item: {
            archive_id: recording_id,
            status: 'started',
            school_id: school.id.to_s,
            course_id: course.id.to_s,
            activity_id: activity.id.to_s,
            user_1_id: user_1.id,
            user_1: { id: user_1.id.to_s, section_id: user_1_section.id.to_s }
          }
        )
      end

      it 'does not write any data to dynamodb and renders an error if the chat parameters' \
         ' are missing both user_1 and users' do
        allow(tokbox_wrapper).to receive(:errors?).and_return(false)
        do_non_pchat_request(bad_chat_params)
        errors = ['Missing user or users parameter']

        expect(VideoChat::TokBoxWrapper).to have_received(:new).with(user)

        expect(tokbox_wrapper).to have_received(:record).with(session_id)

        expect(response).to be_bad_request

        expect(JSON.parse(response.body)).to eq('video_chat' => errors)
      end
    end
  end

  describe 'POST /stop_recording' do
    let(:user) { create(:student) }
    let(:session_id) { SecureRandom.uuid }
    let(:recording_id) { SecureRandom.uuid }
    let(:target_path) do
      video_chat_stop_recording_path(session_id: session_id, recording_id: recording_id)
    end
    let(:tokbox_recording) do
      {
        data: {
          name: 'a recording',
          url: "http://pchat.url/#{recording_id}.mp4"
        },
        id: recording_id,
        status: 'stopped'
      }
    end

    def do_request
      post(target_path)
    end

    include_examples 'require logged in user'

    context 'with a logged in user,' do
      before do
        log_in_user(user)

        allow(dynamo_wrapper).to receive(:update).with(kind_of(Hash))
        allow(tokbox_wrapper).to receive(:stop_recording)
          .with(session_id, recording_id)
          .and_return(tokbox_recording)
      end

      it 'updates the status of the dynamoDB record when the recording has stopped' do
        allow(tokbox_wrapper).to receive(:errors?).and_return(false)

        do_request

        expect(tokbox_wrapper).to have_received(:stop_recording).with(session_id, recording_id)
        expect(dynamo_wrapper).to have_received(:update).with(
          primary_key: { archive_id: recording_id },
          item_updates: { status: 'stopped' }
        )

        expect(response).to be_ok

        expect(JSON.parse(response.body, symbolize_names: true)).to eq(tokbox_recording)
      end

      it 'does not update any dynamoDB element when there are errors stopping a recording' do
        errors = %w[error_1 error_2 error_3]

        allow(tokbox_wrapper).to receive(:errors?).and_return(true)
        allow(tokbox_wrapper).to receive(:errors).and_return(errors)

        do_request

        expect(tokbox_wrapper).to have_received(:stop_recording).with(session_id, recording_id)
        expect(dynamo_wrapper).not_to have_received(:update)

        expect(response).to be_forbidden

        expect(JSON.parse(response.body, symbolize_names: true)).to eq(video_chat: errors)
      end

      it 'renders json with dynamo errors if the dynamo call fails' do
        errors = ['something failed']
        allow(tokbox_wrapper).to receive(:errors?).and_return(false)
        allow(dynamo_wrapper).to receive(:errors?).and_return(true)
        allow(dynamo_wrapper).to receive(:error_messages).and_return(errors)

        do_request

        expect(response).to be_forbidden

        expect(JSON.parse(response.body, symbolize_names: true)).to eq(video_chat: errors)
      end
    end
  end
end
