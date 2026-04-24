describe Instructor::AssignablesController do
  describe 'get index' do
    let(:program) { build_stubbed(:program) }
    let(:focus) { double(Focus) }
    let(:user) { build_stubbed(:instructor) }

    before do
      allow(controller).to receive(:current_program).and_return(program)
      allow(controller).to receive(:current_focus).and_return(focus)
      allow(user).to receive(:has_current_access_to?).and_return(true)
      fake_login(user)
    end

    it 'creates and assigns the presenter' do
      selected_activities = '123,456,789'
      selected_resources = '123,456'

      url_params = {
        selected_activities: selected_activities,
        selected_resources: selected_resources
      }

      presenter_opts = {
        activity_ids: [123, 456, 789],
        resource_ids: [123, 456]
      }

      presenter = double(InstructorAssignablesPresenter)
      expect(InstructorAssignablesPresenter)
        .to receive(:new)
        .with(focus, hash_including(presenter_opts) )
        .and_return(presenter)


      get :index, params: { program_id: program.id }.merge(url_params)
      expect(assigns(:presenter)).to eq(presenter)
    end

    it 'is successful' do
      allow(InstructorAssignablesPresenter).to receive(:new)
      get :index, params: { program_id: program.id, selected_activities: '123, 456' }
      expect(response).to be_successful
      expect(response).to render_template(:index)
    end

    context 'when either activity_ids or resource_ids are blank' do
      it 'is successful when selected_resources are specified but selected_activities is blank' do
        allow(InstructorAssignablesPresenter).to receive(:new)
        get :index, params: { program_id: program.id, selected_resources: '123, 456' }
        expect(response).to be_successful
        expect(response).to render_template(:index)
      end

       it "is successful when selected_activities are specified but selected_resources is blank" do
        allow(InstructorAssignablesPresenter).to receive(:new)
        get :index, params: { program_id: program.id, selected_activities: '123, 456' }
        expect(response).to be_successful
        expect(response).to render_template(:index)
       end

      it 'redirects to the toc and sets a flash error when neither selected_activities or selected_resources are specified' do
        errormsg = 'There was an error processing your request. Please try again.'
        get :index, params: { program_id: program.id }
        expect(response).to redirect_to instructor_toc_path(program.id)
        expect(flash[:error]).to eq(errormsg)
      end
    end
  end
end
