require 'instructor/assessments_controller'

describe Instructor::AssessmentsController do
  before do
    @user = build_stubbed(:instructor)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
    @program = build_stubbed(:program, id: 48)
    allow(Program).to receive(:find_by_id).and_return(@program)
    @course = create(:course)
  end

  before do
    fake_login(@user)
  end

  describe '#index' do
    def do_request
      get :index, params: { program_id: @program.id }
    end

    context 'before_action' do
      context 'logged in user' do
        it_should_behave_like 'an action that requires a logged in instructor'
      end

      context 'contextual help' do
        before do
          allow(ProgramSettings).to receive(:new)
            .and_return(double(ProgramSettings, has_assessment?: true))
        end

        it_should_behave_like 'an action that assigns contextual help'
      end

      context 'component_access' do
        before do
          @expected_redirect = instructor_dashboard_path(@program)
        end
        it_behaves_like 'an action that requires assessment component access'
      end
    end

    context 'assigns' do
      before do
        fake_login(@user)
        allow(ProgramSettings).to receive(:new)
          .and_return(double(ProgramSettings, has_assessment?: true))
        @presenter = double(InstructorAssessmentTocPresenter, start_unit: 'start_unit')
        allow(InstructorAssessmentTocPresenter).to receive(:new).and_return(@presenter)
      end

      it 'should assign presenter' do
        focus = double(Focus, course: @course, sections: [double(Section)], students: [])
        allow(controller).to receive(:current_focus).and_return(focus)
        expect(InstructorAssessmentTocPresenter).to receive(:new).with(
          @program,
          focus,
          @user,
          hash_including('program_id' => @program.id.to_s),
          anything
        ).and_return(@presenter)

        do_request
        expect(assigns(:presenter)).to eq(@presenter)
      end

      it 'should assign page title' do
        do_request
        expect(assigns(:page_title)).to eq('Assessments')
      end

      it 'should set session ' do
        do_request
        expect(session[:activity_return]).to include('label' => 'Return to Assessment')
      end

      it 'should assign sections ' do
        do_request
        expect(assigns(:sections)).to eq([])
      end

      it 'should assign path_options when params exist' do
        default_params = { program_id: @program.id, display_lesson: 10, start_unit: 5, toc_location: 1000 }
        get :index, params: default_params
        expect(assigns(:path_options)).to eq(display_lesson: '10', toc_location: '1000', start_unit: '5')
      end
    end
  end

  describe '#update_assessment' do
    context 'when releasing an assessment whose grades are already available' do
      it 'fail with invalid record error', test_debt: true do
        Timecop.freeze(Time.parse('2000-01-01')) do
          assignment = create(:assignment,
                              assignable_id: nil,
                              due_date: Time.parse('1999-12-28'),
                              show_at: Time.parse('1999-12-28'),
                              show_assessment: 'I release it',
                              grade_availability: 'on_specific_date',
                              grades_available_at: Time.parse('1999-12-29'))

          expect do
            get :update_assessment, params: { program_id: @program.id, assignments: assignment.id, update_type: 'assessment_release' }
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
