describe ResourceComponentsController do
  let(:program) { build_stubbed(:program) }
  let(:user) { build_stubbed(:user) }
  let!(:resource_component) { build_stubbed(:resource_component) }

  describe '#index' do
    let(:presenter) { double(ResourceComponentsPresenter) }
    before do
      allow(user).to receive(:roles).and_return([double(Role, name: Role::RESOURCE_EDITOR)])
      fake_login(user)
      allow(ResourceComponentsPresenter).to receive(:new).and_return(presenter)
      allow(presenter).to receive(:populate).and_return(presenter)
    end

    it 'assigns a new presenter, initialized with specified program id param, and calls populate on it' do
      expect(ResourceComponentsPresenter).to receive(:new).with(program.id.to_s).and_return(presenter)
      expect(presenter).to receive(:populate)
      get :index, params: { program_id: program.id }
      expect(assigns[:presenter]).to eq(presenter)
    end
  end

  describe '#new' do
    before do
      allow(user).to receive(:roles).and_return([double(Role, name: Role::RESOURCE_EDITOR)])
      fake_login(user)
      allow(ResourceComponent).to receive(:new).and_return(resource_component)
    end

    it 'assigns a new resource component' do
      expect(ResourceComponent).to receive(:new).and_return(resource_component)
      get :new, params: { program_id: program.id }
      expect(assigns[:resource_component]).to equal(resource_component)
    end

    it 'renders the new template' do
      get :new, params: { program_id: program.id }
      expect(response).to render_template :new
    end
  end

  describe '#edit' do
    before do
      allow(user).to receive(:roles).and_return([double(Role, name: Role::RESOURCE_EDITOR)])
      fake_login(user)
      allow(ResourceComponent).to receive(:find).and_return(resource_component)
    end

    it 'finds and assigns the component specified by the component id' do
      expect(ResourceComponent).to receive(:find).with(resource_component.id.to_s).and_return(resource_component)
      get :edit, params: { id: resource_component.id, program_id: program.id }
      expect(assigns[:resource_component]).to eql resource_component
    end

    it 'renders the edit template' do
      get :edit, params: { id: resource_component.id, program_id: program.id }
      expect(response).to render_template :edit
    end
  end

  describe '#destroy' do
    before do
      allow(user).to receive(:roles).and_return([double(Role, name: Role::RESOURCE_EDITOR)])
      fake_login(user)
      allow(ResourceComponent).to receive(:find).and_return(resource_component)
      allow(resource_component).to receive(:destroy).and_return(true)
    end

    def do_request
      delete :destroy, params: { program_id: program.id, id: resource_component.id }
    end

    it 'finds and destroys the resource component with the specified id' do
      expect(ResourceComponent).to receive(:find).with(resource_component.id.to_s).and_return(resource_component)
      expect(resource_component).to receive(:destroy)
      do_request
    end

    context 'when delete is successful' do
      it 'redirects to the index action' do
        do_request
        expect(response).to redirect_to(resource_components_path)
      end

      it 'sets a flash success message' do
        do_request
        expect(flash[:notice]).to eql 'Your component was deleted.'
      end
    end

    context 'when delete fails' do
      before do
        allow(resource_component).to receive(:destroy).and_return(false)
      end

      it "redirects to the 'index' action" do
        do_request
        expect(response).to redirect_to(resource_components_path)
      end

      it 'sets a flash error message' do
        do_request
        expect(flash[:error]).to eql 'Could not delete your component.'
      end
    end
  end
end
