describe Instructor::CourseLibraryController do
  let(:unit) { build_stubbed(:unit) }
  let(:lesson) { unit.lessons.first }
  let(:section) { build_stubbed(:section, course: course) }
  let(:course) { build_stubbed(:course) }
  let(:activity) { build_stubbed(:activity) }
  let(:instructor) { build_stubbed(:instructor) }
  let(:default_params) { { section_id: section.id, activity_id: activity.id, program_id: @program.id } }

  before do
    allow(Activity).to receive(:find).and_return(activity)
    allow(activity).to receive(:lesson).and_return(unit.lessons.first)
    allow(@controller).to receive(:current_section).and_return(section)
  end

  describe '#hide' do
    def do_request(params= {})
      post :hide, params: default_params.merge(params)
    end

    before do
      populate_instructor_program_and_focus(course: course, instructor: instructor)
      fake_login(instructor)
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    it 'removes the activity from the course library' do
      expect(CourseLibraryActivity).to receive(:hide_activity).with(activity.id.to_s, course.id)
      do_request
    end
  end

  describe '#unhide' do
    def do_request(params= {})
      post :unhide, params: default_params.merge(params)
    end

    before do
      populate_instructor_program_and_focus(course: course, instructor: instructor)
      fake_login(instructor)
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    it 'adds the activity to the course library' do
      expect(CourseLibraryActivity).to receive(:unhide_activity).with(activity.id.to_s, course.id)
      do_request
    end

    it 'returns success as true' do
      do_request
      result = JSON.parse(response.body)
      expect(result['success']).to eq(true)
    end
  end
end
