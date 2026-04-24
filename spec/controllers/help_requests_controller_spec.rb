describe HelpRequestsController do
  let(:activity) { build_stubbed(:activity) }
  let(:user) { build_stubbed(:student) }
  let(:section) { build_stubbed(:section) }
  let(:program) { build_stubbed(:program) }

  describe '#index' do
    let(:presenter) { double('HelpRequestsPresenter') }

    before do
      fake_login(user)
      allow(HelpRequestsPresenter).to receive(:new).and_return(presenter)
      allow(presenter).to receive(:populate).and_return(presenter)
      allow(controller).to receive(:require_program_access).and_return(true)
    end

    def do_request(params = {})
      get :index, params: { section_id: section }.merge(params)
    end

    it_behaves_like 'an action that requires a logged in user'

    it 'assigns an instance of HelpRequestsPresenter' do
      do_request
      expect(assigns(:presenter)).to eq(presenter)
    end

    it 'populates requests info' do
      expect(presenter).to receive(:populate).and_return(presenter)
      do_request
    end
  end

  describe '#activity_index' do
    let(:scope) { double('scope', include_users: [help_request]) }
    let(:help_request) { build_stubbed(:help_request) }

    let(:default_params) { { format: 'json', section_id: section.id, activity_id: activity.id } }

    before do
      fake_login(user)
      allow(user.help_requests).to receive(:instructor_respondable_by_section_and_activity).and_return(scope)
    end

    def do_request(params = {})
      get :activity_index, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in user'

    it 'finds help requests for the current user for the specified section id and activity id' do
      expect(user.help_requests).to receive(:instructor_respondable_by_section_and_activity).with(section.id.to_s, activity.id.to_s).and_return(scope)

      do_request
    end

    it 'renders the help requests found as JSON' do
      do_request

      expect(response.body).to eq([help_request].to_json(HelpRequest::ACTIVITY_JSON_OPTIONS))
    end
  end

  describe '#destroy' do
    let(:help_request) { build_stubbed(:help_request, user: user, activity: activity, program: program) }
    let(:help_requests_scope) { double('scope', find: help_request) }

    before do
      fake_login(user)
      allow(user).to receive(:help_requests).and_return(help_requests_scope)
      allow(help_request).to receive(:destroy)
    end

    def do_request
      delete :destroy, params: { id: help_request.id }
    end

    it_behaves_like 'an action that requires a logged in user'

    it 'finds the help_request with the specified id for the current user' do
      expect(user).to receive(:help_requests).and_return(help_requests_scope)
      expect(help_requests_scope).to receive(:find).with(help_request.id.to_s).and_return(help_request)

      do_request
    end

    it 'destroys the help request specified by the id param' do
      expect(help_request).to receive(:destroy)

      do_request
    end
  end
end
