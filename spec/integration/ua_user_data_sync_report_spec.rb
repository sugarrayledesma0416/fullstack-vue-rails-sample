feature 'ua_data_sync_reporter' do
  let(:basic_auth_user) { 'iron_keep_b6eef' }
  let(:basic_auth_password) { 'password' }
  let(:basic_auth_credentials) do
    ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, basic_auth_password)
  end

  let(:student) { create(:student) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let!(:active_enrollment) { create(:active_enrollment, section: section, user: student) }
  let!(:dropped_enrollment) { create(:dropped_enrollment, section: section, user: student) }

  def data_sync_reporter(user_guid:)
    get "/ua/user_data_sync_report/#{user_guid}",
        params: {},
        headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }
  end

  describe '#get', type: :request do
    before do
      HTTP_AUTHENTICATIONS[basic_auth_user] = basic_auth_password
    end

    scenario 'when the user does not exist' do
      user = build_stubbed(:user)
      data_sync_reporter(user_guid: user.guid)

      expect(response.status).to eq 422
      expect(response.body).to eq(Coluche::UserDataSyncReport.new(user_guid: user.guid).process.to_json)
    end

    scenario 'when the user exists' do
      user = student
      data_sync_reporter(user_guid: user.guid)

      expect(response.status).to eq 200
      expect(response.body).to eq(Coluche::UserDataSyncReport.new(user_guid: user.guid).process.to_json)
    end
  end
end
