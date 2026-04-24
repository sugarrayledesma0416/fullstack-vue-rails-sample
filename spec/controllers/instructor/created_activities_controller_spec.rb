describe Instructor::CreatedActivitiesController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson, toc_entries: [strand]) }
  let!(:concept) do
    create(
      :concept,
      id: strand.location,
      lesson:,
      program:
    )
  end

  let(:course) { create(:course) }

  describe '#index' do
    let(:created_activity) { create(:activity) }
    let(:default_params) do
      {
        display_lesson: lesson.id,
        program_id: program.id,
        start_unit: 5,
        toc_location: 1000
      }
    end

    before do
      populate_instructor_program_and_focus(
        course:,
        instructor:
      )
      fake_login(instructor)
      allow_any_instance_of(InstructorContentPresenter).to receive(:lesson_activities).and_return([])
    end

    def do_request(params = {})
      get :index, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'

    it 'assigns path_options when exist' do
      do_request
      expect(assigns(:path_options)).to eq(
        display_lesson: lesson.id.to_s,
        start_unit: '5',
        toc_location: '1000'
      )
    end
  end

  describe '#new' do
    let(:created_activity) { create(:activity) }
    let(:default_params) do
      {
        activity_type: 'composition',
        lesson_id: lesson.id,
        program_id: program.id,
        toc_entry_id: strand.location
      }
    end

    before do
      populate_instructor_program_and_focus(
        course:,
        instructor:
      )

      fake_login(instructor)
      allow(InstructorCreatedActivity).to receive(:new).and_return(created_activity)
    end

    def do_request(params = {})
      get :new, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'

    it 'assigns activity_type' do
      do_request
      expect(assigns(:activity_type)).to eq('composition')
    end

    it 'displays a formatted activity header' do
      do_request
      expect(assigns(:activity_list_header)).to eq(
        "#{lesson.display_name} | #{strand.name}"
      )
    end

    it 'flags that the activity is in the assessment tab' do
      concept.update(assessment: true)
      do_request

      expect(assigns(:is_assessment_tab)).to be true
    end
  end

  describe '#edit' do
    let(:activity) do
      create(
        :instructor_created_activity,
        activity_type: 'composition',
        instructor_id: instructor.id,
        lesson:
      )
    end

    let(:default_params) do
      {
        id: activity.id,
        program_id: program.id,
        lesson_id: lesson.id,
        toc_entry_id: strand.location
      }
    end

    before do
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_concept)
      allow(Maestro::LicenseGroup)
        .to receive(:all)
        .and_return([double(id: 1, name: 'Test License Group')])
      allow(InstructorCreatedActivity).to receive(:find).and_return(activity)

      populate_instructor_program_and_focus(
        course:,
        instructor:
      )

      fake_login(instructor)
    end

    def do_request(params = {})
      get :edit, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'

    context 'when page parameter is provided' do
      it 'assigns @page with the provided param' do
        page_number = '3'
        do_request(page: page_number)
        expect(assigns(:page)).to eq(page_number)
      end
    end

    context 'when page parameter is not provided' do
      it 'assings @page with the default value 1' do
        do_request
        expect(assigns(:page)).to eq(1)
      end
    end
  end

  describe '#assign_activity_preview_prerequisites' do
    let(:activity) do
      create(
        :instructor_created_activity,
        instructor_id: instructor.id,
        lesson:
      )
    end
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_concept)
      allow(Maestro::LicenseGroup)
        .to receive(:all)
        .and_return([double(id: 1, name: 'Test License Group')])
      controller.instance_variable_set(:@activity, activity)
      content_object = instance_double(
        MaestroActivityEngine::ActivityContent::GroupChatContent,
        min_students_selection: 2,
        max_students_selection: 5
      )
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(controller).to receive(:current_user).and_return(user)

      controller.send(:assign_activity_preview_prerequisites)
    end

    it 'assigns @activity_presenter as a Struct' do
      activity_presenter = controller.instance_variable_get(:@activity_presenter)
      expect(activity_presenter).to be_a(Struct)
    end

    it 'assigns @activity_presenter.activity correctly' do
      activity_presenter = controller.instance_variable_get(:@activity_presenter)
      expect(activity_presenter.activity).to eq(activity)
    end

    it 'assigns @activity_presenter.user correctly' do
      activity_presenter = controller.instance_variable_get(:@activity_presenter)
      expect(activity_presenter.user).to eq(user)
    end

    it 'assigns correct group chat configuration' do
      activity_presenter = controller.instance_variable_get(:@activity_presenter)
      expect(activity_presenter.group_chat_selection_config).to eq(
        {
          group_maximum: 5,
          group_minimum: 2
        }
      )
    end

    it 'ensures track_time? returns false' do
      activity_presenter = controller.instance_variable_get(:@activity_presenter)
      expect(activity_presenter.track_time?).to be_falsey
    end
  end
end
