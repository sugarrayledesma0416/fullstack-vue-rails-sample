describe Instructor::StudentGracePeriodsController do
  let(:program) { build_stubbed(:program) }
  let(:course) { build_stubbed(:course, program: program) }
  let(:section) { build_stubbed(:section, course: course) }
  let(:instructor) { build_stubbed(:instructor) }

  before do
    allow(instructor).to receive(:has_current_access_to?).and_return(true)
    allow(controller).to receive(:current_program).and_return(program)
    fake_login(instructor)
    allow(Program).to receive(:find).and_return(program)
  end

  describe 'index' do
    it 'assigns a presenter' do
      get :index, params: { program_id: 1, course_id: 2 }
      expect(assigns(:presenter)).not_to be_nil
    end
  end

  describe 'create' do
    def do_request(opts = {})
      defaults = { selected_student_ids: [1000], course_id: 10, program_id: 1, return_to: 'return path' }
      post :create, params: defaults.merge(opts)
    end

    context 'when there are errors' do
      before do
        allow(flash).to receive(:sweep)
      end

      context 'parameter errors' do
        it 'displays a flash error when there are no students selected' do
          do_request(selected_student_ids: nil)
          expect(flash[:error]).to eq('You must select at least one student.')
        end
      end

      context 'insufficient grace periods' do
        it 'displays a flash error when there are not enough grace periods for the selected students' do
          allow(Course).to receive(:find).and_return(build_stubbed(:course))
          allow(Maestro::School).to receive(:grace_period_allocation).and_return({ 'number_used' => 1, 'number_allowed' => 1 }.as_json)
          do_request
          expect(flash[:error]).to eq('Your school does not have enough grace periods available for the selected students.')
        end
      end
    end

    context 'when successful' do
      let(:student) { FactoryBot.create(:student) }
      let(:focus) { double('Focus') }
      let(:course) { FactoryBot.create(:course) }

      before do
        allow(Maestro::School).to receive(:grace_period_allocation).and_return({ 'number_used' => 0, 'number_allowed' => 5 }.as_json)
        allow(Maestro::User).to receive(:grant_student_grace_period_access).and_return(status: 200, body: '', headers: {})
        allow(focus).to receive(:students).and_return([student])
        allow(controller).to receive(:current_focus).and_return(focus)
      end

      it 'redirects to the return_to value' do
        return_to = '/return/path'
        do_request(selected_student_ids: [student.id], return_to: return_to, course_id: course.id)
        expect(response).to redirect_to return_to
      end

      it 'processes the selected students' do
        expect(Maestro::User).to receive(:grant_student_grace_period_access).with(student.guid, course.guid).and_return(status: 200, body: '', headers: {})
        do_request(selected_student_ids: [student.id], course_id: course.id)
      end
    end
  end
end
