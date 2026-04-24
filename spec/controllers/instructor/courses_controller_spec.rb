describe Instructor::CoursesController do
  let!(:user) { build_stubbed(:instructor) }
  let(:school) { create(:school) }
  let(:program) { build_stubbed(:program) }
  let!(:course) do
    build_stubbed(:course, name: 'Foo', owner: user, program: program)
  end
  let(:other_instructor) { build_stubbed(:instructor) }
  let(:other_instructor_course) do
    build_stubbed(:course, owner: other_instructor, program: program)
  end

  before do
    allow(user).to receive(:has_current_access_to?).and_return(true)
    allow(Program).to receive(:find_by_id).and_return(program)
    allow_any_instance_of(CourseOptionsSerializer).to receive(:as_json).and_return('')
    allow(School).to receive(:find).and_return(school)
  end

  describe '#show' do
    before do
      allow(user).to receive(:most_recent_school_id).and_return(school.id)
      allow(user).to receive(:schools).and_return([school])
      fake_login(user)
      allow(Course).to receive(:find).and_return(course)
    end

    context 'when a standard http get request is issued' do
      it 'raise a 403 error' do
        get :show, params: { program_id: program.id, id: course.id }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#new' do
    let(:course_options) { double('CourseOptions') }

    before do
      allow(user).to receive(:most_recent_school_id).and_return(school.id)
      allow(user).to receive(:schools).and_return([school])
      fake_login(user)
      allow(program).to receive(:units).and_return([build_stubbed(:unit), build_stubbed(:unit)])
      allow(Maestro::CoursePackage).to receive(:all).and_return([])
      allow(Maestro::CoursePackage).to receive(:all_for_courses).and_return([])
      allow(CourseOptions).to receive(:new).and_return(course_options)
      allow(Course).to receive(:new).and_return(course)
      allow(controller).to receive(:require_course_policy_permission)
    end

    def do_request
      get :new, params: { program_id: program.id, school_id: school.id }
    end

    def do_request_with_guids
      get :new, params: { program_id: program.id, school_id: school.guid, guids: 'true' }
    end

    def do_request_with_no_guids
      get :new, params: { program_id: program.id, school_id: school.id, guids: '' }
    end

    it 'sets the cache buster' do
      expect(controller).to receive(:set_cache_buster)
      do_request
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns contextual help'

    it 'consults the course management policy' do
      expect(controller).to receive(:require_course_policy_permission)
      do_request
    end

    it 'makes a new course with default settings' do
      attributes = {
        program_id: program.id,
        school_id: school.id,
        first_unit_id: program.units.first.id,
        last_unit_id: program.units.last.id,
        start_date: instance_of(Date),
        end_date: instance_of(Date)
      }
      expect(Course).to receive(:new).with(hash_including(attributes))
      do_request
    end

    it 'receives guids and redirects after replacing with ids' do
      do_request_with_guids
      expect(response).to redirect_to(instructor_new_course_url(program_id: program.id, school_id: school.id))
    end

    it 'receives empty string guids flag so does not redirect' do
      do_request_with_no_guids
      expect(response).to render_template :new
    end

   context 'when a JSON request' do
      def do_request
        get :new, params: { program_id: program.id, school_id: school.id, format: :json }
      end

      it 'renders the course options' do
        do_request
        expect(response.status).to eq(200)
      end
    end
  end

  describe '#edit' do
    before do
      allow(Course).to receive(:find).and_return(course)
      @valid_params = { program_id: program.id, id: course.id }
      fake_login(user)
      allow(controller).to receive(:require_course_policy_permission)
    end

    def do_request(params = {})
      get :edit, params: @valid_params.merge(params)
    end

    it 'sets the cache buster' do
      expect(controller).to receive(:set_cache_buster)
      do_request
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns contextual help'

    it 'consults the course management policy' do
      expect(controller).to receive(:require_course_policy_permission)
      do_request
    end

    it 'assigns the course' do
      expect(Course).to receive(:find).with(course.id.to_s).and_return(course)
      do_request
      expect(assigns(:course)).to eq(course)
    end

    context 'with an HTML request,' do
      it 'renders the default music v1 layout' do
        do_request
        expect(response).to render_template('layouts/music_v1/default')
      end

      context 'when user is not the course owner,' do
        before do
          allow(Course).to receive(:find).and_return(other_instructor_course)
          do_request
        end

        it 'redirects to instructor dashboard' do
          expect(response).to redirect_to instructor_dashboard_path(course.program)
        end

        it 'sets a flash error message' do
          expect(flash[:error]).to eq(
            described_class::COURSE_OWNER_REQUIRED_MESSAGE
          )
        end
      end
    end

    context 'with a JSON request,' do
      it 'renders the course options' do
        do_request(format: :json)

        expect(response.status).to eq(200)
      end
    end

    context 'when user is not the course owner,' do
      before do
        allow(Course).to receive(:find).and_return(other_instructor_course)
        do_request(format: :json)
      end

      it 'sets a response status of forbidden' do
        expect(response).to be_forbidden
      end

      it 'renders text with an error message' do
        expect(response.body).to eq(
          described_class::COURSE_OWNER_REQUIRED_MESSAGE
        )
      end
    end
  end

  describe '#destroy' do
    before do
      allow(course).to receive(:archive)
      allow(Course).to receive(:find).and_return(course)
      fake_login(user)
    end

    def do_request
      delete :destroy, params: { program_id: program.id, id: course.id }
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    it 'assigns the course' do
      expect(Course).to receive(:find).with(course.id.to_s).and_return(course)
      do_request
      expect(assigns(:course)).to eq(course)
    end

    it 'calls the archive method on the course' do
      expect(course).to receive(:archive)
      do_request
    end

    it 'should redirect to dashboard if there are no errors' do
      do_request
      expect(flash[:notice]).to eq("Course <b>#{course.name}</b> was deleted successfully.")
      expect(response).to redirect_to instructor_dashboard_path(program_id: course.program_id)
    end

    it 'should redirect to dashboard if there are errors' do
      course.errors.add(:base, 'Fake error')
      do_request
      expect(response).to redirect_to instructor_dashboard_path(program_id: course.program_id)
    end

    context 'when user is not the course owner,' do
      before do
        allow(Course).to receive(:find).and_return(other_instructor_course)
        do_request
      end

      it 'redirects to instructor dashboard' do
        expect(response).to redirect_to instructor_dashboard_path(course.program)
      end

      it 'sets a flash error message' do
        expect(flash[:error]).to eq(
          described_class::COURSE_OWNER_REQUIRED_MESSAGE
        )
      end
    end
  end

  describe '#show_summary_pdf' do
    let(:packages) { ['Package 1', 'Package 2'] }

    before do
      allow(Course).to receive(:new).and_return(course)
      fake_login(user)
      # Actually allowing the pdf to render makes these tests take 3 seconds each to run.
      allow(controller).to receive(:render)
    end

    def do_pdf
      course_params = {
        program_id: program.id,
        id: course.id,
        course_data: URI.encode_www_form_component({}.to_json),
        course_packages_names: URI.encode_www_form_component(packages.to_json),
        format: :pdf
      }
      get :show_summary_pdf, params: course_params
    end

    it 'assigns a course' do
      do_pdf
      expect(assigns(:course)).to eq(course)
    end

    it 'assigns course packages names' do
      do_pdf
      expect(assigns(:course_packages_names)).to eq packages
    end

    it 'renders a pdf formatted summary page' do
      # this one needs to render in order to pass.
      allow(controller).to receive(:render).and_call_original
      do_pdf
      expect(response.content_type).to eq('application/pdf')
    end
  end

  describe '#content_step' do
    let(:valid_params) do
      return { program_id: program.id, id: course.id, format: :json }
    end

    before do
      allow(Course).to receive(:find).and_return(course)
      fake_login(user)
      allow(controller).to receive(:require_course_policy_permission)
      allow(course).to receive(:has_individual_assignments?).and_return(true)
    end

    def do_request(params = {})
      get :content_step, params: valid_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'

    it 'consults the course management policy' do
      do_request
      expect(controller).to have_received(:require_course_policy_permission)
    end

    it 'assigns the course' do
      do_request
      expect(assigns(:course)).to eq(course)
    end

    it 'renders the course_has_individual_assignments' do
      do_request
      expect(JSON.parse(response.body)).to eq(
        'course_has_individual_assignments' => true
      )
    end

    it 'returns response status 200' do
      do_request
      expect(response.status).to eq(200)
    end

    context 'when user is not the course owner,' do
      before do
        allow(Course).to receive(:find).and_return(other_instructor_course)
        do_request(format: :json)
      end

      it 'sets a response status of forbidden' do
        expect(response).to be_forbidden
      end

      it 'renders text with an error message' do
        expect(response.body).to eq(
          described_class::COURSE_OWNER_REQUIRED_MESSAGE
        )
      end
    end
  end
end
