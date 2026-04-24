describe Gradebook::EmailController do
  let(:program) { build_stubbed(:program) }
  let(:course) { build_stubbed(:course) }
  let(:section) { build_stubbed(:section) }
  let(:student) { build_stubbed(:student) }
  let(:instructor) { build_stubbed(:instructor) }

  describe '#list' do
    def do_request
      default_params = { return_to: "/gradebook/#{program.id}", program_id: program.id }
      get :list, params: default_params
    end

    before do
      allow(instructor).to receive(:has_current_access_to?).and_return(true)
      fake_login(instructor)
      @instructor = @user = instructor
      @program = program
      @course = course
      @sections = [section]
      @students = [student]
      @focus = double(Focus, course: @course, sections: @sections, students: @students, type: 'foo')
      allow(Focus).to receive(:new).and_return(@focus)
      allow(controller).to receive(:current_focus).and_return(@focus)
      allow(controller).to receive(:current_program).and_return(program)
      allow(controller).to receive(:current_user).and_return(instructor)
    end

    it_should_behave_like 'an action that assigns program and focus'
    it_should_behave_like 'an action that requires a logged in instructor'

    it 'assigns a return to param' do
      do_request
      expect(assigns(:return_to)).to eq("/gradebook/#{program.id}")
    end

    it 'assigns a list of students from the focus' do
      do_request
      expect(assigns(:students)).to eq([student])
    end
  end
end
