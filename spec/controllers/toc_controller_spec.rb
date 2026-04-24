describe TocController do
  include ApplicationHelper

  describe '#show' do
    before do
      @user = build_stubbed(:student)
    end

    def basic_setup
      fake_login(@user)
      allow(@user).to receive(:has_current_access_to?).and_return(true)
    end

    def section_setup
      @program = build_stubbed(:program_with_toc_entries)
      allow(Program).to receive(:find).and_return(@program)
      allow(controller).to receive(:current_program).and_return(@program)
      @course = build_stubbed(:course)

      @section = build_stubbed(:section)
      allow(Section).to receive(:find_by).and_return(@section)
      allow(@section).to receive(:course).and_return(@course)
      allow(@section).to receive(:program).and_return(@program)
    end

    def do_request(params = {})
      get :show, params: {
        section_id: @section.id.to_s,
        program_id: @section.program.id.to_s
      }.merge(params)
    end

    context 'before_action' do
      context 'logged in user' do
        before do
          section_setup
        end
        it_should_behave_like 'an action that requires a logged in user'
      end

      context 'program access' do
        before do
          fake_login(@user)
          section_setup
        end

        def do_request_with_section(section)
          do_request
        end

        it_should_behave_like 'a page that requires program access'
      end

      context 'reroute_instructor' do
        context 'when logged in user is an instructor' do
          it 'should redirect the user to instructor_toc_path' do
            instructor = build_stubbed(:instructor)
            fake_login(instructor)
            allow(instructor).to receive(:has_current_access_to?).and_return(true)
            section_setup
            do_request
            expect(response).to redirect_to(instructor_toc_path(@program))
          end
        end
      end
    end

    context 'assigns' do
      before do
        basic_setup
        section_setup
        @presenter = double(StudentTocPresenter , start_unit: 'start_unit')
      end

      it 'should assign presenter' do
        expect(StudentTocPresenter).to receive(:new).with(@program,
                                                          @user,
                                                          @section,
                                                          hash_including('section_id' => @section.id.to_s,
                                                                         'program_id' => @section.program.id.to_s),
                                                          nil,
                                                          @section.id.to_s).and_return(@presenter)

        do_request
        expect(assigns(:presenter)).to eq(@presenter)
      end

      it 'should assign page title' do
        allow(StudentTocPresenter).to receive(:new).and_return(@presenter)
        do_request
        expect(assigns(:page_title)).to eq('Activities')
      end

      it 'should set session ' do
        allow(StudentTocPresenter).to receive(:new).and_return(@presenter)
        do_request
        #not should if this assignment is equired any more
        expect(session[:activity_return]).to include('label' => 'Return to Activities')
      end
    end

    context 'given a user with a section' do
      before do
        basic_setup
        section_setup
      end

      it 'sets a an activity return_url that includes their section id' do
        do_request
        expect(session[:activity_return]['url']).to include section_toc_path(@section, @section.program)
      end
    end

    context 'given a user without a section' do
      before do
        basic_setup
        section_setup
      end

      it 'sets a an activity return_url that includes a zero section id' do
        do_request(section_id: '0')
        expect(session[:activity_return]['url']).to include section_toc_path(0, @section.program)
      end
    end

    describe 'activity_return url stored in the session' do
      before do
        basic_setup
        section_setup
      end

      context 'when a non-blank display_lesson param is specified' do
        it 'stores an activity_return url that includes that display_lesson param' do
          display_lesson = 12345
          do_request(display_lesson: display_lesson)
          expected_url = section_toc_path(@section, @program, display_lesson: display_lesson)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a blank display_lesson param is specified' do
        it 'stores an activity_return url that does not include a display_lesson param' do
          do_request(display_lesson: '')
          expected_url = section_toc_path(@section, @program)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a non-blank start_unit param is specified' do
        it 'stores an activity_return url that includes that start_unit param' do
          start_unit = 12345
          do_request(start_unit: start_unit)
          expected_url = section_toc_path(@section, @program, start_unit: start_unit)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a blank start_unit param is specified' do
        it 'stores an activity_return url that does not include a start_unit param' do
          do_request(start_unit: '')
          expected_url = section_toc_path(@section, @program)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a non-blank toc_location param is specified' do
        it 'stores an activity_return url that includes that toc_location param' do
          toc_location = 12345
          do_request(toc_location: toc_location)
          expected_url = section_toc_path(@section, @program, toc_location: toc_location)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a blank toc_location param is specified' do
        it 'stores an activity_return url that does not include a toc_location param' do
          do_request(toc_location: '')
          expected_url = section_toc_path(@section, @program)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end
    end
  end

  describe '#strand_permalink' do
    let(:program) { create(:program_with_toc_entries) }
    let(:lesson) { program.units.first.lessons.first }
    let(:strand) { lesson.toc_entries.first }

    context 'when the user is a student' do
      let(:student) { create(:student) }

      before { fake_login(student) }

      it 'redirects the student to the correct url if they are in an active section for this program' do
        course = create(:course, program: program)
        section = create(:section, course: course)
        student.enrollments.create! section: section, state: 'enrolled'

        get :strand_permalink, params: { lesson_id: lesson.id, toc_location_id: strand.location }

        expect(response).to redirect_to(
          section_toc_path(
            section,
            program,
            display_lesson: lesson,
            toc_location: strand.location,
            start_unit: program.best_start_unit_rank(0)
          )
        )
      end

      it 'redirects the student to a section zero url if they are not in an active section' do
        get :strand_permalink, params: { lesson_id: lesson.id, toc_location_id: strand.location }

        expect(response).to redirect_to(
          section_toc_path(
            0,
            program,
            display_lesson: lesson,
            toc_location: strand.location,
            start_unit: program.best_start_unit_rank(0)
          )
        )
      end
    end

    context 'when the user is an instructor' do
      let(:instructor) { create(:instructor) }

      before { fake_login(instructor) }

      it 'redirects the instructor to the correct url' do
        get :strand_permalink, params: { lesson_id: lesson.id, toc_location_id: strand.location }

        expect(response).to redirect_to(
          instructor_toc_path(
            program,
            display_lesson: lesson,
            toc_location: strand.location,
            start_unit: program.best_start_unit_rank(0)
          )
        )
      end
    end
  end
end
