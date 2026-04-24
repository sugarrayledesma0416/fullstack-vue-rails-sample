describe ReportedProblemsController do
  let(:activity) { build_stubbed(:activity) }
  let(:user) { build_stubbed(:student) }
  let(:program) { build_stubbed(:program) }

  describe '#index' do
    let(:presenter) { double('HelpRequestsPresenter') }

    before do
      fake_login(user)
      allow(user).to receive(:has_current_access_to?).and_return(true)
      allow(Program).to receive(:find).and_return(program)
      allow(controller).to receive(:current_program).and_return(program)
      allow(controller).to receive(:best_default_path).and_return('/best_default_path')
      allow(HelpRequestsPresenter).to receive(:new).and_return(presenter)
      allow(presenter).to receive(:populate).and_return(presenter)
    end

    def do_request(params = {})
      get :index, params: { program_id: program.id.to_s }.merge(params)
    end

    it_behaves_like 'an action that requires a logged in user'

    it 'assigns an instance of HelpRequestsPresenter' do
      expect(HelpRequestsPresenter).to receive(:new).with(nil, user, nil, :reported_problems).and_return(presenter)
      do_request
      expect(assigns(:presenter)).to eq(presenter)
    end

    it 'populates requests info' do
      expect(presenter).to receive(:populate).and_return(presenter)
      do_request
    end
  end
end
