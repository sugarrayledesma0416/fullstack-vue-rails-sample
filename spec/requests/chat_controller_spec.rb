require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe ChatController do
  describe 'POST /group_chat_channel_authorize' do
    let(:user) { create(:user) }
    let(:pnub_client_wrapper) { instance_double(Pnub::ClientWrapper, create_grants: true) }

    before do
      allow(Pnub::ClientWrapper).to receive(:new).with(user).and_return(pnub_client_wrapper)
      allow(pnub_client_wrapper).to receive(:chat_session_data).and_return([])
      allow(pnub_client_wrapper).to receive(:grants_ttl).and_return(1440)
    end

    def do_request
      post group_chat_channel_authorize_path
    end

    include_examples 'require logged in user'

    context 'when grant is successful' do
      before do
        log_in_user(user)
        allow(pnub_client_wrapper).to receive(:grants_successful?).and_return(true)
      end

      it 'gets a successful response' do
        do_request
        expect(response.status).to eq 200
      end

      it 'gets the right payload structure' do
        do_request
        expect(JSON.parse(response.body).keys).to contain_exactly('info', 'pubnub_token_info')
      end
    end

    context 'when grant fails' do
      before do
        log_in_user(user)
        allow(pnub_client_wrapper).to receive(:grants_successful?).and_return(false)
        allow(pnub_client_wrapper).to receive(:grant_responses_with_errors).and_return({})
      end

      it 'gets a forbidden response' do
        do_request
        expect(response.status).to eq 403
      end

      it 'gets the right payload structure' do
        do_request
        expect(JSON.parse(response.body).keys).to contain_exactly('message', 'error')
      end
    end
  end
end
