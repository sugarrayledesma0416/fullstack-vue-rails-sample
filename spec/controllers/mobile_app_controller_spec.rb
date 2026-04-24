describe MobileAppController do
  let(:program) { build_stubbed(:program) }
  let(:user) { build_stubbed(:student) }
  let(:access_guardian) { double('AccessGuardian', has_mobile_app?: true) }

  before do
    allow(controller).to receive(:current_program).and_return(program)
    allow(controller).to receive(:access_guardian).and_return(access_guardian)
    allow(user).to receive(:has_current_access_to?).and_return(true)
    allow(user).to receive(:current_section_in_program).and_return(nil)
  end

  describe '#show' do
    before do
      fake_login(user)
    end

    def do_request(params = {})
      get :show, params: { program_id: program.id }.merge(params)
    end

    it_behaves_like 'an action that requires a logged in user'
    it_behaves_like 'an action that requires program access'

    context 'when user does not have mobile app access' do
      it 'redirects to ua home page' do
        allow(access_guardian).to receive(:has_mobile_app?).and_return(false)
        do_request
        expect(response).to redirect_to ua_home_path
      end
    end
  end
end
