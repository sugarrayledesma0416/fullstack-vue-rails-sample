describe SectionsController do
  let(:access_guardian) do
    double('AccessGuardian',
           can_access_content?: true,
           has_grace_period?: false,
           has_mobile_app?: false)
  end

  it_should_have_help

  before do
    allow(controller).to receive(:access_guardian).and_return(access_guardian)
  end

  context 'login requirement' do
    before do
      @user = build_stubbed(:student)
      @program = build_stubbed(:program)
      allow(controller).to receive(:current_program).and_return(@program)
      @course = build_stubbed(:course, name: 'this course name')
      @section = build_stubbed(:section, course: @course, instructor: build_stubbed(:instructor))
      allow(Section).to receive(:find_by).with(id: @section.id.to_s).and_return(@section)
      @lesson_1 = build_stubbed(:lesson_with_toc_entries)
      @presenter = double(StudentDashboardPresenter, current_lessons: [@lesson_1], active_enrollment?: true)
      allow(StudentDashboardPresenter).to receive(:new).and_return(@presenter)
    end

    it_should_require_a_logged_in_user { get :show, params: { course_id: @course.id.to_s, section_id: @section.id.to_s } }
  end

  context 'section_header' do
    before do
      @user = build_stubbed(:student)
      @course = build_stubbed(:course, name: 'this course name')
      @section = build_stubbed(:section, course: @course, instructor: build_stubbed(:instructor))
      allow(@section).to receive(:course_name)
      allow(Section).to receive(:find_by).with(id: @section.id.to_s).and_return(@section)
      @lesson_1 = build_stubbed(:lesson_with_toc_entries)
      @presenter = double(StudentDashboardPresenter, current_lessons: [@lesson_1], active_enrollment?: true)
      allow(StudentDashboardPresenter).to receive(:new).and_return(@presenter)
    end

    it_should_assign_section_header do
      get :show, params: { course_id: '1', section_id: '2' }
    end
  end

  context 'stub before actions' do
    before do
      allow(controller).to receive(:assign_section_header)
    end

    describe 'GET #show' do
      def do_request_with_section(section)
        get :show, params: { course_id: section.course.id.to_s, section_id: section.id.to_s }
      end

      it_should_behave_like 'a page that requires program access'

      context 'always , shared specs' do
        before do
          @user = build_stubbed(:student)
          allow(@user).to receive(:has_current_access_to?).and_return(true)
          fake_login(@user)

          @program = build_stubbed(:program)
          allow(controller).to receive(:current_program).and_return(@program)

          @course = build_stubbed(:course, name: 'this course name')
          @section = build_stubbed(:section, course: @course, instructor: build_stubbed(:instructor))

          allow(Section).to receive(:find_by).and_return(@section)
          allow(@user).to receive(:sections).and_return([@section])
          @menu_location = 'dashboard'

          @lesson_1 = build_stubbed(:lesson_with_toc_entries)
          @presenter = double(StudentDashboardPresenter, current_lessons: [@lesson_1], active_enrollment?: true)
          allow(StudentDashboardPresenter).to receive(:new).and_return(@presenter)
        end

        def do_request
          get :show, params: { course_id: @course.id.to_s, section_id: @section.id.to_s }
        end

        it_should_behave_like 'an action that assigns contextual help'
        it_should_behave_like 'an action that assigns menu location'
      end

      context 'always' do
        before do
          @user = build_stubbed(:student)
          allow(@user).to receive(:has_current_access_to?).and_return(true)
          fake_login(@user)

          @program = build_stubbed(:program)
          allow(controller).to receive(:current_program).and_return(@program)

          @course = build_stubbed(:course, name: 'this course name')
          @section = build_stubbed(:section, course: @course, instructor: build_stubbed(:instructor))

          allow(Section).to receive(:find_by).and_return(@section)
          allow(@user).to receive(:sections).and_return([@section])
          @lesson_1 = build_stubbed(:lesson_with_toc_entries)
          @presenter = double(StudentDashboardPresenter, current_lessons: [@lesson_1], active_enrollment?: true)
          allow(StudentDashboardPresenter).to receive(:new).and_return(@presenter)

          get :show, params: { course_id: @course.id.to_s, section_id: @section.id.to_s }
        end

        it 'assigns @section' do
          expect(assigns(:section)).to eq(@section)
        end

        it 'assigns @course' do
          expect(assigns(:course)).to eq(@section.course)
        end

        it 'assigns @instructor' do
          expect(assigns(:instructor)).to eq(@section.instructor)
        end

        it 'should assign @presenter' do
          expect(assigns(:presenter)).not_to be_nil
        end

        it 'should store the activity return link' do
          expect(session[:activity_return]['label']).to eq('Return to Dashboard')
          expect(session[:activity_return]['url']).to eq(course_section_path(@course, @section))
        end
      end

      context 'when a user has never visited a course dashboard before,' do
        it 'sets the first_dashboard_viewed_at date' do
          user = build_stubbed(:student, first_dashboard_viewed_at: nil)
          allow(user).to receive(:has_current_access_to?).and_return(true)

          @lesson_1 = build_stubbed(:lesson_with_toc_entries)
          @presenter = double(StudentDashboardPresenter, current_lessons: [@lesson_1], active_enrollment?: true)
          allow(StudentDashboardPresenter).to receive(:new).and_return(@presenter)

          program = build_stubbed(:program)
          section = build_stubbed(:section, course: build_stubbed(:course))
          allow(section).to receive(:program).and_return(program)
          allow(Section).to receive(:find_by).with(id: section.id.to_s).and_return(section)
          allow(user).to receive(:sections).and_return([section])
          freeze_time = Time.zone.now
          allow(Time).to receive(:now).and_return(freeze_time)
          expect(user).to receive(:update).with(first_dashboard_viewed_at: freeze_time.to_s(:db))
          fake_login(user)
          get :show, params: { course_id: section.course.id.to_s, section_id: section.id.to_s }
        end
      end

      context 'when user is an instructor' do
        let(:instructor) { build_stubbed(:instructor) }
        let(:program) { build_stubbed(:program) }
        let(:course) { build_stubbed(:course) }
        let(:section) { build_stubbed(:section, course: course) }

        it 'redirects to the instructor dashboard' do
          allow(instructor).to receive(:has_current_access_to?).and_return(true)
          allow(controller).to receive(:current_program).and_return(program)
          fake_login(instructor)
          get :show, params: { course_id: section.course.id.to_s, section_id: section.id.to_s }
          expect(response).to redirect_to instructor_dashboard_path(program.id)
        end
      end
    end

    describe '#no_section_dashboard_show' do
      before do
        @program = build_stubbed(:program_with_lessons)
        @user = build_stubbed(:student)
        allow(@user).to receive(:has_current_access_to?).and_return(true)
        fake_login(@user)
        get :no_section_dashboard_show, params: { section_id: 0, program_id: @program.id.to_s }
      end

      it 'should render a no section template' do
        expect(response).to render_template 'no_section_show'
      end

      it 'should have a message describing the error' do
        expect(assigns(:message)).to eq('You need to be actively enrolled in a course in order to have a dashboard.')
      end
    end

    describe '#no_section_calendar_show' do
      before do
        @program = build_stubbed(:program_with_lessons)
        @user = build_stubbed(:student)
        allow(@user).to receive(:has_current_access_to?).and_return(true)
        fake_login(@user)
        get :no_section_calendar_show, params: { section_id: 0, program_id: @program.id.to_s }
      end

      it 'should render a no section template' do
        expect(response).to render_template 'no_section_show'
      end

      it 'should have a message describing the error' do
        expect(assigns(:message)).to eq('You need to be actively enrolled in a course in order to have an assignment calendar.')
      end
    end

    describe '#no_section_assesments_show' do
      before do
        @program = build_stubbed(:program_with_lessons)
        @user = build_stubbed(:student)
        allow(@user).to receive(:has_current_access_to?).and_return(true)
        fake_login(@user)
        get :no_section_assessments_show, params: { section_id: 0, program_id: @program.id.to_s }
      end

      it 'should render a no section template' do
        expect(response).to render_template 'no_section_show'
      end

      it 'should have a message describing the error' do
        expect(assigns(:message)).to eq('You need to be actively enrolled in a course in order to access assessments.')
      end
    end

    describe '#study_schedule' do
      def do_request_with_section(section)
        get :study_schedule, params: { course_id: section.course.id.to_s, section_id: section.id.to_s }
      end

      it_should_behave_like 'a page that requires program access'

      it_should_behave_like 'an action that blocks maestro2 programs'

      context 'with assignments' do
        before do
          @program = build_stubbed(:program)
          allow(Program).to receive(:find_by_id).and_return(@program)
          @user = build_stubbed(:student)
          allow(@user).to receive(:has_current_access_to?).with(@program).and_return(true)
          fake_login(@user)

          @course = build_stubbed(:course, program: @program, name: 'this course name')
          @section = build_stubbed(:section, course: @course, instructor: build_stubbed(:instructor))
          allow(@controller).to receive(:current_section).and_return(@section)
          allow(@section).to receive(:program).and_return(@program)

          allow(Section).to receive(:find_by).and_return(@section)
          allow(@user).to receive(:sections).and_return([@section])

          @calendar_presenter = CalendarPresenter.new(@user, Date.today, @program, section: @section)
          allow(CalendarPresenter).to receive(:new).and_return(@calendar_presenter)
          allow(@calendar_presenter).to receive(:build_calendar)
        end

        def do_request
          get :study_schedule, params: { course_id: @section.course.id.to_s, section_id: @section.id.to_s }
        end

        it_should_behave_like 'an action that assigns contextual help'

        it 'should create an assignment calendar' do
          expect(CalendarPresenter).to receive(:new).with(
            @user,
            Date.today,
            @program,
            { section: @section }
          ).and_return(@calendar_presenter)
          expect(@calendar_presenter).to receive(:build_calendar)
          do_request_with_section(@section)
        end

        it 'sets the assignments' do
          do_request_with_section(@section)
          expect(assigns(:calendar_presenter)).to eq(@calendar_presenter)
        end

        it 'assigns the section' do
          do_request_with_section(@section)
          expect(assigns(:section)).to eq(@section)
        end

        it 'assigns the course' do
          do_request_with_section(@section)
          expect(assigns(:course)).to eq(@course)
        end

        it 'should store the activity return link' do
          do_request_with_section(@section)
          expect(session[:activity_return]['label']).to eq('Return to Calendar')
          expect(session[:activity_return]['url']).to eq(study_schedule_path)
        end
      end
    end

    describe '#show_calendar' do
      before do
        @user = build_stubbed(:student)
        allow(@user).to receive(:has_current_access_to?).and_return(true)
        fake_login(@user)
        @course = build_stubbed(:course, name: 'this course name')
        @section = build_stubbed(:section, course: @course, instructor: build_stubbed(:instructor))
        @year_month = '2012-08'
      end

      it 'should render the calendar' do
        allow(controller).to receive(:build_calendar_presenter)
        get :show_calendar, params: { course_id: @section.course.id.to_s, section_id: @section.id.to_s, year_month: @year_month }
        expect(controller).to render_template('calendar/_event_calendar')
      end
    end
  end
end

