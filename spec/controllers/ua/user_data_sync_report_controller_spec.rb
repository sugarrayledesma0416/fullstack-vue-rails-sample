describe Ua::UserDataSyncReportController do
  let(:instructor) { create(:instructor) }

  before do
    basic_auth_user = 'iron_keep_b6eef'
    password = 'test'
    HTTP_AUTHENTICATIONS[basic_auth_user] = password
    request.env['HTTP_AUTHORIZATION'] =
      ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)
  end

  describe '#index' do
    def do_request(params)
      get :index, params: params
    end

    context 'when passed invalid user guid,' do
      let(:invalid_user_guid) { 'invalid user guid' }

      it 'returns failure' do
        do_request(user_guid: invalid_user_guid)
        expect(response.status).not_to eq(200)
      end

      it 'returns a json message' do
        do_request(user_guid: invalid_user_guid)
        expect(response.header['Content-Type']).to include 'application/json'
      end

      it 'returns a validation error messages' do
        do_request(user_guid: invalid_user_guid)
        expect(JSON.parse(response.body, symbolize_names: true)).to include(
          errors: ['User not found.']
        )
      end
    end

    context 'when passed valid user guid' do
      let(:user) { create(:user) }

      it 'returns success' do
        do_request(user_guid: user.guid)
        expect(response.status).to eq(200)
      end

      it 'returns a json message' do
        do_request(user_guid: user.guid)
        expect(response.header['Content-Type']).to include 'application/json'
      end

      it 'returns no error messages' do
        do_request(user_guid: user.guid)
        expect(JSON.parse(response.body, symbolize_names: true)).to include(
          errors: []
        )
      end
    end
  end
end
