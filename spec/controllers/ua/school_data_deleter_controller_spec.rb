describe Ua::SchoolDataDeleterController do
  describe '#delete_school_data' do
    let(:school) { create(:school) }

    before do
      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)
    end

    def do_request(school_guid: school.guid)
      post(:delete_school_data, params: { school_guid: school_guid }, xhr: true)
    end

    context 'when passed invalid school guid' do
      it 'returns a 404 status code' do
        do_request(school_guid: 'invalid school guid')

        expect(response.status).to eq(404)
      end
    end

    it 'enqueues a job to delete school data' do
      expect(SchoolDataDeleterWorker).to receive(:perform_async).with(school.id)

      do_request
    end

    it 'returns a 200 status code' do
      do_request

      expect(response.status).to eq(200)
    end
  end
end
