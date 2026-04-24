describe Ua::UserDataDeleterController do
  describe '#delete_user_data' do
    let(:user) { create(:user) }

    before do
      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)
    end

    def do_request(user_guid: user.guid)
      post(:delete_user_data, params: { user_guid: user_guid }, xhr: true)
    end

    context 'when passed invalid user guid' do
      it 'returns a 404 status code' do
        do_request(user_guid: 'invalid user guid')

        expect(response.status).to eq(404)
      end
    end

    it 'enqueues a job to delete user data' do
      expect(UserDataDeleterWorker).to receive(:perform_async).with(user.id)

      do_request
    end

    it 'returns a 200 status code' do
      do_request

      expect(response.status).to eq(200)
    end
  end
end
