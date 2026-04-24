describe UsersController do
  describe 'PUT update_gender' do
    let(:user) { build_stubbed(:student) }

    before do
      fake_login(user)
      allow(User).to receive(:find).and_return(user)
      allow(user).to receive(:save!).and_return(true)
    end

    def do_request(params = {})
      put :update_gender, params: { id: user.id }.merge(params), xhr: true
    end

    it_should_behave_like 'an action that requires a logged in user'

    it 'updates the user' do
      expect(user).to receive(:save!)
      do_request(user: { gender: 'Male' })
    end
  end
end
