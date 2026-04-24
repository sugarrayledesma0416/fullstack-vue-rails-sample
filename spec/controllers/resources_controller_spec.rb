describe ResourcesController do
  describe '#index' do
    before do
      @program = create(:program)
      @user = build_stubbed(:student)
      allow(@user).to receive(:current_section_in_program)
      allow(@user).to receive(:has_current_access_to?).and_return(true)
      fake_login(@user)
    end

    def do_request(params = {})
      get :index, params: { program_id: @program.id.to_s }
    end

    def do_request_with_section(section)
      get :index, params: { program_id: @program.id.to_s, section_id: section.id.to_s }
    end

    it_should_behave_like 'an action that requires a logged in user'
    it_should_behave_like 'a page that requires program access'

    it 'assigns the presenter' do
      expect(ResourcesPresenter).to receive(:new)
      get :index, params: { program_id: @program.id.to_s }
    end

    it 'assigns section' do
      section = build_stubbed(:section_with_course)
      allow(@controller).to receive(:current_section).and_return(section)
      do_request_with_section(section)
      expect(assigns[:section]).to eq(section)
    end
  end

  describe '#edit' do
    let(:program) { build_stubbed(:program) }
    let(:instructor) { build_stubbed(:instructor) }
    let(:resource) { build_stubbed(:resource) }

    before do
      allow(Program).to receive(:find_by_id).and_return(program)
      allow(instructor).to receive(:has_current_access_to?).and_return(true)
      fake_login(instructor)
      allow(Resource).to receive(:find).and_return(resource)
      allow(resource).to receive(:editable_by?).and_return(true)
    end

    def do_request(params ={})
      default_params = { program_id: program.id, id: resource.id, resource: { title: 'I am temp title' } }
      get :edit, params: default_params.merge(params)
    end

    it 'checks that the resource is editable by the current user' do
      expect(resource).to receive(:editable_by?).with(instructor).and_return(true)
      do_request
    end

    it 'finds and assigns a resource with the specified id' do
      expect(Resource).to receive(:find).with(resource.id.to_s).and_return(resource)
      do_request
      expect(assigns[:resource]).to eq(resource)
    end

    context 'when the resource is editable by the user' do
      it 'renders the edit view' do
        allow(resource).to receive(:editable_by?).and_return(true)
        do_request
        expect(response).to render_template :edit
      end
    end

    context 'when the resource is not editable' do
      it 'redirects to home' do
        allow(resource).to receive(:editable_by?).and_return(false)
        do_request
        expect(response).to redirect_to root_url
      end
    end
  end

  describe '#download_multiple' do
    let(:program) { build_stubbed(:program_with_lessons) }
    let(:lesson) { build_stubbed(:lesson_with_unit, unit_id: program.units.first.id) }
    let(:resource) { build_stubbed(:resource) }

    before do
      @instructor = build_stubbed(:instructor)
      allow(Program).to receive(:find_by_id).and_return(program)
      allow(@instructor).to receive(:has_current_access_to?).and_return(true)
      fake_login(@instructor)
    end

    def do_request(params = {})
      get :download_multiple, params: params.merge(format: :zip)
    end

    context 'when valid params are specified' do
      before do
        allow(Resource).to receive(:find).and_return([resource])
      end

      it 'serve the zip file for the selected resource' do
        expect(@controller).to receive(:zipline).with(kind_of(Enumerator::Lazy), 'downloaded_resources.zip')
        do_request(program_id: program.id, selected_resources: resource.id.to_s)
        expect(response).to be_successful
      end
    end
  end

  describe '#download' do
    let(:expected_signed_url) { 'http://example.com/signed_url' }

    before do
      @program = create(:program_with_lessons)
      @lesson = build_stubbed(:lesson_with_unit, unit_id: @program.units.first.id)
      @resource = build_stubbed(:resource, start_unit_id: @program.units.first.id, lesson_id: @lesson.id, program_id: @program.id)
      @instructor = build_stubbed(:instructor)
      allow(Program).to receive(:find_by_id).and_return(@program)
      allow(@instructor).to receive(:has_current_access_to?).and_return(true)
      fake_login(@instructor)
      allow(Resource).to receive(:find)
    end

    def do_request(params = {})
      get :download, params: params
    end

    context 'when valid params are specified' do
      it 'finds and redirects to the file for the resource' do
        expect(@instructor).to receive(:downloadable_resource).with(@resource.id.to_s, @program, Section.section_zero).and_return(@resource)
        allow(@resource).to receive(:signed_url).and_return(expected_signed_url)
        do_request id: @resource.id, program_id: @program.id
        expect(response).to redirect_to(expected_signed_url)
      end
    end

    context 'when no file exists for the specified resource' do
      it 'redirects to a 404 page' do
        allow(@instructor).to receive(:downloadable_resource).and_return(@resource)
        allow(@resource).to receive(:file_name).and_return('')
        do_request id: @resource.id, program_id: @program.id
        expect(response).to redirect_to('/404')
      end
    end

    context 'when the resource has been instructor-uploaded' do
      it 'finds and redirects to the file for the uploaded resource' do
        resource = build_stubbed(:resource, start_unit_id: @program.units.first.id, lesson_id: @lesson.id, program_id: @program.id, uploaded: true)
        allow(@instructor).to receive(:downloadable_resource).and_return(resource)
        allow(resource).to receive(:signed_url).and_return(expected_signed_url)
        do_request id: resource.id, program_id: @program.id
        expect(response).to redirect_to(expected_signed_url)
      end
    end
  end

  describe '#new' do
    before do
      @program = build_stubbed(:program_with_lessons)
      @resource = build_stubbed(:resource)
      allow(Resource).to receive(:new).and_return(@resource)
      @instructor = build_stubbed(:instructor)
      allow(Program).to receive(:find_by_id).and_return(@program)
      allow(@instructor).to receive(:has_current_access_to?).and_return(true)
      fake_login(@instructor)
      @page_header = 'Add a Resource'
    end

    def do_request(params = {})
      get :new, params: { program_id: @program.id.to_s }.merge!(params)
    end

    it_should_behave_like 'an action that requires a logged in instructor or grader'

    it 'should assign the header text' do
      do_request
      expect(assigns(:page_header)).to eql @page_header
    end

    it 'should assign the return url' do
      do_request return_to: 'resource_index_path'
      expect(assigns(:return_to)).to eql 'resource_index_path'
    end

    context 'when a component has been selected as refinement' do
      it 'should assign the selected component id value' do
        expected_component_id = 123
        do_request return_to: "resource_index_path?component_id=#{expected_component_id.to_s}"
        expect(assigns(:selected_component_id)).to eql expected_component_id
      end
    end

    context 'when a start_unit_id is present in the return_to_params' do
      it 'should extract and assign the start_unit_id' do
        expected_start_unit_id = '3140'
        return_to_path = "/resources/programs/347?component_id=5244+start_unit_id=#{expected_start_unit_id}"
        do_request return_to: return_to_path
        expect(assigns(:start_unit_id)).to eql expected_start_unit_id
      end
    end

    it 'should assign a new Resource object' do
      do_request
      expect(assigns(:resource)).to eql @resource
    end
  end

  describe '#delete' do
    before do
      @program = build_stubbed(:program_with_lessons)
      @resource = build_stubbed(:resource)
      allow(Resource).to receive(:find).and_return(@resource)
      allow(Program).to receive(:find_by_id).and_return(@program)
      @instructor = build_stubbed(:instructor)
      allow(@instructor).to receive(:has_current_access_to?).and_return(true)
      allow(InstructorResourceSetting).to receive(:find_by_user_id_and_resource_id)
      @resource_setting = build_stubbed(:instructor_resource_setting, user_id: @instructor.id, resource_id: @resource.id, student_visibility: 'shown')
      @section = build_stubbed(:section)
      fake_login(@instructor)
      allow(@resource).to receive(:update).and_return(true)
    end

    def do_request(params ={})
      delete :destroy, params: params
    end

    context 'when valid params' do
      it 'Should delete the resource selected' do
        expect(Resource).to receive(:find).with(@resource.id.to_s).and_return(@resource)
        expect(@resource).to receive(:update!).with(is_archived: true)
        do_request(id: @resource.id.to_s, program_id: @program.id)
      end

      it 'should return to resources list', test_debt: true do
        skip 'dgiraldo'
        expect(Resource).to receive(:find).with(@resource.id.to_s).and_return(@resource)
        expect(@resource).to receive(:update!).with(is_archived: true).and_return(true)
        expect(InstructorResourceSetting).to receive(:find_by_user_id_and_resource_id).with(@instructor.id, @resource.id).and_return(@resource_setting)
        do_request(id: @resource.id.to_s, program_id: @program.id)
        expect(flash[:notice]).to eql "Resource '#{@resource.title}' has been deleted."
        expect(response).to redirect_to instructor_program_resources_path(@program)
      end
    end
  end
end
