describe Instructor::LearningTracksController do
  let!(:user) { build_stubbed(:instructor) }
  let(:school) { build_stubbed(:school) }
  let(:program) { build_stubbed(:program, family: 'vista_online_learning') }
  let!(:course) do
    build_stubbed(:course,
                  name: 'Foo',
                  owner: user,
                  program: program)
  end

  before do
    allow(user).to receive(:has_current_access_to?).and_return(true)
    allow(Program).to receive(:find_by_id).and_return(program)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#external_items' do
    let(:expected_items) do
      [
        {
          id: external_activity_1.id,
          day_id: external_assignment_1.day_id,
          name: external_activity_1.name
        }, {
          id: external_activity_2.id,
          day_id: external_assignment_2.day_id,
          name: external_activity_2.name
        }
      ]
    end

    let(:external_activity_1) do
      instance_double(GradebookEngine::ExternalActivity, id: 1, name: 'A')
    end

    let(:external_activity_2) do
      instance_double(GradebookEngine::ExternalActivity, id: 2, name: 'B')
    end

    let(:external_activity_3) do
      instance_double(GradebookEngine::ExternalActivity, id: 3, name: 'C')
    end

    let(:external_assignment_1) do
      instance_double(
        GradebookEngine::ExternalAssignment,
        day_id: Time.now.utc.to_date + 1,
        external_activity: external_activity_1,
        section: section_1
      )
    end

    let(:external_assignment_2) do
      instance_double(
        GradebookEngine::ExternalAssignment,
        day_id: Time.now.utc.to_date + 1,
        external_activity: external_activity_2,
        section: section_1
      )
    end

    let(:external_assignment_3) do
      instance_double(
        GradebookEngine::ExternalAssignment,
        day_id: Time.now.utc.to_date + 1,
        external_activity: external_activity_3,
        section: section_2
      )
    end

    let(:gradebook_api) { GradebookEngine::GradebookAPI }

    let(:params) do
      {
        section_id: section_1.id
      }
    end
    let(:section_1) { build_stubbed(:section) }
    let(:section_2) { build_stubbed(:section) }

    before do
      fake_login(user)
    end

    def do_request(extra_params = {})
      get :external_items, params: params.merge(extra_params), format: :json
    end

    it 'renders the external items for the section' do
      allow(gradebook_api).to receive(:find_external_items_by_section).with(section_1.id.to_s)
                                                                      .and_return(expected_items)
      do_request
      expect(gradebook_api).to have_received(:find_external_items_by_section)
    end
  end

  describe '#learning_tracks' do
    before do
      fake_login(user)
    end

    def do_request(params = {})
      default_params = { program_id: '333', school_id: '222', format: :json }
      get :learning_tracks, params: default_params.merge(params)
    end

    it 'renders learning tracks JSON for the program' do
      server_directory = M3::Application.config.current_deployed_env_name
      filepath = Pathname.new("datafiles/#{server_directory}/learning_tracks/333/333.json")
      mock_exporter = double(LearningTrack::ActivityExporter)
      expect(Program).to receive(:find).with('333').and_return(program)
      expect(LearningTrack::ActivityExporter).to receive(:new).with(program).and_return(mock_exporter)
      expect(mock_exporter).to receive(:activities_json)
      do_request
    end
  end

  describe '#section_learning_track' do
    let(:section) do
      build_stubbed(:section,
                    id: 100,
                    name: 'Bar',
                    course: course)
    end
    let(:course_package) { double('Maestro::CoursePackage', id: 1) }
    let(:track) { SectionLearningTrack.new(section, [course_package], nil) }
    let(:activity) { { 'id' => 2, 'group' => 'Learn' } }
    let(:params) do
      {
        program_id: '48',
        school_id: '999',
        section_id: section.id,
        format: :json
      }
    end

    before do
      fake_login(user)
      allow(Maestro::CoursePackage).to receive(:all_for_course).and_return([course_package])
      allow(track).to receive(:activities).and_return([activity])
      allow(SectionLearningTrack).to receive(:new).and_return(track)
      allow(Section).to receive(:including_enterprise).and_return(double(find: section))
    end

    def do_request(extra_params = {})
      get :section_learning_track, params: params.merge(extra_params)
    end

    it 'finds the correct section' do
      allow(Section).to receive(:including_enterprise).and_return(double(find: section))
      do_request
    end

    it 'renders the correct JSON' do
      do_request
      expected = {
        'activities' => [activity],
        'course_package_ids' => [1],
        'description' => 'Foo (30 weeks)',
        'strands' => [],
        'first_unit_id' => nil,
        'last_unit_id' => nil,
        'units' => [],
        'categories' => {},
        'insufficient_license_groups' => false
      }
      expect(JSON.parse(response.body)).to eq(expected)
    end

    it 'fetches course packages from the API' do
      expect(Maestro::CoursePackage).to receive(:all_for_course).
        with(course.guid).and_return([course_package])
      do_request
    end

    context 'when a current course id is not specified in the params' do
      it 'creates a section learning track with a nil course id' do
        expect(SectionLearningTrack).to receive(:new).
          with(section, [course_package], nil).and_return(track)
        do_request
      end
    end

    context 'when a current course id is specified in the params' do
      it 'creates a section learning track with that id' do
        expect(SectionLearningTrack).to receive(:new).with(
          section, [course_package], '5'
        ).and_return(track)
        do_request(current_course_id: '5')
      end
    end
  end
end
