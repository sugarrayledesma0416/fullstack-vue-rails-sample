describe AssessmentsController do
  before do
    allow(controller).to receive(:assign_section_header)
  end

  describe '#index' do
    context 'always' do
      before do
        @user = build_stubbed(:student)
        @program = build_stubbed(:program_with_toc_entries, id: 48)
        allow(@controller).to receive(:current_program).and_return(@program)
        allow(@controller).to receive(:ensure_correct_section).and_return(true)
        allow(@controller).to receive(:require_program_access).and_return(true)
        allow(Program).to receive(:find).and_return(@program)
        @course = create(:course, program: @program)
        @section = build_stubbed(:section, course: @course)
        allow(Section).to receive(:find).and_return(@section)
        allow(controller).to receive(:current_section).and_return(@section)
        fake_login(@user)
      end

      def do_request
        get :index, params: { program_id: @program.id, section_id: @section.id }
      end

      it_should_behave_like 'an action that requires a logged in student'

      context 'checks contextual help' do
        before do
          program_settings = double(ProgramSettings)
          allow(program_settings).to receive(:has_assessment?).and_return true
          allow(ProgramSettings).to receive(:new).and_return(program_settings)
        end

        it_should_behave_like 'an action that assigns contextual help'
      end

      context 'component_access' do
        before do
          @expected_redirect = course_section_path(@course, @section)
        end
        it_behaves_like 'an action that requires assessment component access'
      end

      it 'assigns an AssessmentsPresenter' do
        program_settings = double(ProgramSettings)
        allow(program_settings).to receive(:has_assessment?).and_return true
        allow(ProgramSettings).to receive(:new).and_return(program_settings)
        presenter = AssessmentsPresenter.new(@program, @section, @user)
        allow(AssessmentsPresenter).to receive(:new).and_return(presenter)
        do_request
        expect(assigns(:presenter)).to eq(presenter)
      end

      it 'assigns a return to link url and label' do
        program_settings = double(ProgramSettings)
        allow(program_settings).to receive(:has_assessment?).and_return true
        allow(ProgramSettings).to receive(:new).and_return(program_settings)
        expected_return_info = {
          'label' => 'Return to Assessment',
          'url' => student_assessments_path(@program, @section) + '#past_assessments'
        }
        do_request
        expect(session[:activity_return]).to eq(expected_return_info)
      end
    end

    context '#ensure_correct_section' do
      let(:program) { build_stubbed(:program) }
      let(:student) { build_stubbed(:student) }
      let(:section) { build_stubbed(:section) }
      let(:correct_section) { build_stubbed(:section) }

      before do
        allow(@controller).to receive(:current_program).and_return(program)
        allow(@controller).to receive(:current_section).and_return(section)
        allow(@controller).to receive(:require_program_access).and_return(true)
        allow(student).to receive(:has_access_to_section_in_program?)
          .with(section, program, session).and_return(false)
        allow(AssessmentsPresenter).to receive(:new)
      end

      context 'if user does not have access to given section' do
        it 'redirect to assessment path of the current section for the program if its available' do
          allow(student).to receive(:current_section_in_program).and_return(correct_section)
          fake_login(student)
          get :index, params: { program_id: program.id, section_id: section.id }
          expect(response).to redirect_to(student_assessments_path(program, correct_section))
        end

        it 'redirect to assessment path of the section zero if the current for the program is not available' do
          allow(student).to receive(:current_section_in_program).and_return(nil)
          fake_login(student)
          get :index, params: { program_id: program.id, section_id: section.id }
          expect(response).to redirect_to(student_assessments_path(program, Section.section_zero))
        end
      end
    end
  end
end
