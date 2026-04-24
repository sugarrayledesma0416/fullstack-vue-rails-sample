describe Instructor::SectionsController, core: true do
  let(:presenter) do
    instance_double(
      SectionsPresenter,
      build_additional_instructors: true,
      previous_sections_for_course: {},
      section: @section
    )
  end

  before do
    @user = build_stubbed(:instructor)
    @another_instructor = build_stubbed(:instructor)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
    fake_login(@user)

    @program = build_stubbed(:program)
    allow(Program).to receive(:find_by_id).and_return(@program)

    @course = create(:course, program: @program, school: build_stubbed(:school))
    allow(Course).to receive(:find_by_id).and_return(@course)

    @old_course = build_stubbed(:course)
    @old_section = build_stubbed(:section, created_at: 10.months.ago)

    allow(@user).to receive(:courses_for_program).and_return([@old_course])
    allow(@old_course).to receive(:sections).and_return([@old_section])

    @section = build_stubbed(
      :section,
      course: @course,
      created_at: 2.months.ago,
      instructor: @user,
      time_zone: nil
    )
    allow(@course).to receive(:sections).and_return([@section])

    allow(Section).to receive(:new).and_return(@section)
    allow(Section).to receive(:find).and_return(@section)
    allow(controller).to receive(:instructor_team_attributes_in_session).and_return([])

    allow(Maestro::School).to receive(:instructors)
      .and_return('instructor_ids' => [@user.id, @another_instructor.id],
                  'instructor_guis' => [@user.guid, @another_instructor.guid])

    allow(SectionsPresenter).to receive(:new).and_return(presenter)
  end

  describe '#show' do
    context 'when a standard http get request is issued' do
      it 'should raise a 403 error' do
        get :show, params: {
          program_id: @program.id,
          course_id: @course.id,
          id: @section.id
        }
        expect(response.code).to eq('403')
      end
    end
    context 'when an ajax get request is issued,' do
      it 'should render the hover partial' do
        get :show, params: {
          program_id: @program.id,
          course_id: @course.id,
          id: @section.id
        }, xhr: true
        expect(response.code).to eq('200')
      end
    end
  end

  describe '#new' do
    before do
      @default_params = { instructor_id: @user.id, course_id: @course.id }
      allow(SectionOptions).to receive(:new)
    end

    def do_request
      get :new, params: { program_id: @program.id, course_id: @course.id }
    end

    def do_request_with_guids
      get :new, params: {
        program_id: @program.id,
        course_id: @course.guid,
        guids: 'true'
      }
    end

    def do_request_with_no_guids
      get :new, params: { program_id: @program.id, course_id: @course.id, guids: '' }
    end

    it 'sets the cache buster' do
      expect(controller).to receive(:set_cache_buster)
      do_request
    end

    it_should_behave_like 'an action that assigns contextual help'

    it 'should render the new template' do
      do_request
      expect(response).to render_template :new
    end

    it 'receives guids and redirects after replacing with ids' do
      do_request_with_guids
      expect(response).to redirect_to(new_instructor_course_section_url(program_id: @program.id, course_id: @course.id))
    end

    it 'receives empty string guids flag so does not redirect' do
      do_request_with_no_guids
      expect(response).to render_template :new
    end

    context 'when the responding to a json request' do
      def do_request
        get :new, params: {
          program_id: @program.id,
          course_id: @course.id,
          format: :json
        }
      end

      it 'creates a new presenter' do
        do_request

        expect(SectionsPresenter).to have_received(:new).with(
          @user,
          @program,
          ActionController::Parameters.new({ 'course_id' => @course.id.to_s }).permit!
        )
      end

      it 'renders back the data needed for the section wizard' do
        expect(SectionOptions).to receive(:new)
        do_request
      end

      it 'builds additional instructors' do
        sections_presenter = double('SectionsPresenter').as_null_object
        allow(SectionsPresenter).to receive(:new).and_return(sections_presenter)
        expect(sections_presenter).to receive(:build_additional_instructors)
        do_request
      end
    end
  end

  describe '#edit' do
    context 'with a JSON request,' do
      def do_request
        get :edit, params: {
          program_id: @program.id,
          course_id: @course.id,
          id: @section.id,
          format: :json
        }
      end

      before do
        allow(SectionOptions).to receive(:new)
      end

      it 'sets the cache buster' do
        expect(controller).to receive(:set_cache_buster)
        do_request
      end

      it 'creates a sections presenter' do
        do_request

        expect(SectionsPresenter).to have_received(:new).with(
          @user,
          @program,
          ActionController::Parameters.new({ 'course_id' => @course.id.to_s, 'id' => @section.id.to_s }).permit!
        )
      end

      it 'renders back the data needed for the section wizard' do
        do_request

        expect(SectionOptions).to have_received(:new)
      end

      it 'builds additional instructors' do
        do_request

        expect(presenter).to have_received(:build_additional_instructors)
      end
    end

    context 'with an html request,' do
      before do
        @valid_params = {
          course_id: @course.id,
          id: @section.id,
          program_id: @program.id
        }
        allow(controller.instance_eval { flash }).to receive(:sweep)
      end

      def do_request(params = {})
        get :edit, params: @valid_params.merge(params)
      end

      it_should_behave_like 'an action that assigns contextual help'

      it 'assigns a presenter' do
        do_request

        expect(SectionsPresenter).to have_received(:new).with(
          @user,
          @program,
          ActionController::Parameters.new({ 'course_id' => @course.id.to_s, 'id' => @section.id.to_s }).permit!
        )
      end

      it 'sets a flash error if the current user is not the section owner' do
        @section.instructor = build_stubbed(:instructor)

        do_request

        expect(flash[:error]).to eq(
          described_class::SECTION_OWNER_REQUIRED_MESSAGE
        )
      end

      it 'should render the edit template' do
        do_request
        expect(response).to render_template :edit
      end
    end
  end

  describe '#destroy' do
    before do
      allow(Program).to receive(:find).and_return(@program)
      allow(@section).to receive(:archive)
    end

    def do_request
      delete :destroy, params: {
        program_id: @program.id,
        course_id: @course.id,
        id: @section.id
      }
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    it 'creates a sections presenter' do
      do_request

      expect(SectionsPresenter).to have_received(:new).with(
        @user,
        @program,
        ActionController::Parameters.new({ 'course_id' => @course.id.to_s, 'id' => @section.id.to_s }).permit!
      )
    end

    context 'when the current user is the section owner,' do
      it 'archives the section' do
        do_request

        expect(@section).to have_received(:archive)
      end

      it 'redirects to the instructor dashboard if there are no errors' do
        do_request

        expect(flash[:notice]).to eq(
          "Section <b>#{@section.name}</b> was deleted successfully."
        )
        expect(response).to redirect_to instructor_dashboard_path(
          program_id: @course.program_id
        )
      end

      it 'redirects to the instructor dashboard if there are errors' do
        @section.errors.add(:base, 'Fake error')

        do_request

        expect(flash[:error]).to eq('Fake error')
        expect(response).to redirect_to instructor_dashboard_path(
          program_id: @course.program_id
        )
      end
    end

    context 'when the current user is not the section owner,' do
      before do
        @section.instructor = @another_instructor
      end

      it 'does not archive the section' do
        do_request
        expect(@section).not_to have_received(:archive)
      end

      it 'sets a flash error' do
        do_request
        expect(flash[:error]).to eq(described_class::SECTION_OWNER_REQUIRED_MESSAGE)
      end
    end
  end
end
