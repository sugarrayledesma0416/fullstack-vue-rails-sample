require 'instructor/activities_controller'
describe Instructor::ActivitiesController, core: true do
  describe '#show_activity' do
    let(:presenter) do
      double(InstructorActivityPresenter,
             activity_list_header: 'activity header',
             lesson_header: 'my lesson header',
             video_settings: true)
    end
    let(:activity) { build_stubbed(:activity) }
    let(:student) { build_stubbed(:student) }
    let(:course) {  build_stubbed(:course) }
    let(:section) { build_stubbed(:section, course: course) }
    let(:mock_results) { double('student_results') }
    let(:course_policy) { double('course_library_edit_policy') }
    let(:attempt) do
      double('Attempt',
             attempt_track: true,
             current_view: :complete,
             results: mock_results,
             cms_revision_id: 1)
    end

    let(:classwork) { double('Classwork', current_workset: false) }

    before do
      populate_instructor_program_and_focus(course: course, sections: [section])
      allow(InstructorActivityPresenter).to receive(:new).and_return(presenter)
      allow(Activity).to receive(:find).and_return(activity)
      allow(Student).to receive(:find).and_return(student)
      allow(Classwork).to receive(:new).and_return(classwork)
      allow(CourseLibraryEditPolicy).to receive(:new).and_return(course_policy)
      allow(classwork).to receive(:find_or_new_attempt).and_return(attempt)
      allow(@controller).to receive(:current_section).and_return(section)
      allow(presenter).to receive(:activity_in_study_plan=).with(boolean)
      allow(attempt).to receive(:activity=).with(instance_of(activity.class))
      allow(activity).to receive(:vtext_link=)
      allow(activity).to receive(:activity_type).and_return('fill_in_the_blanks')
      content = double('ContentObject', activity_type: 'vocab_list', groups: [], has_rubric?: false)
      allow(activity).to receive(:content_object).and_return(content)
      student_grade = double(GradebookEngine::StudentGradeFinder,
                             grade: double(GradebookEngine::Grade, submitted?: false,
                                                                   adjusted?: false))
      allow(GradebookEngine::StudentGradeFinder).to receive(:new)
        .and_return(student_grade)
    end

    def do_request
      get :show, params: { id: activity.id, user_id: student.id, program_id: @program.id }
    end

    it_should_have_help
    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'

    it 'creates, populates and assigns an InstructorActivityPresenter presenter, passing in activity, student and section' do
      expect(InstructorActivityPresenter).to receive(:new).with(activity, student, section, course).and_return(presenter)
      do_request

      expect(assigns(:activity_presenter)).to eq(presenter)
    end

    it 'assigns the results from the attempt' do
      do_request
      expect(assigns(:results)).to eq(mock_results)
    end

    it 'assigns return_label' do
      do_request
      expect(assigns(:return_label)).to eq('Return to student requests')
    end

    it 'assigns video_settings' do
      do_request
      expect(assigns(:video_settings)).to eq(true)
    end

    it 'assigns course_policy' do
      do_request
      expect(assigns(:course_policy)).to eql(course_policy)
    end

    it 'assigns lesson_header' do
      allow(InstructorActivityPresenter).to receive(:new).and_return(presenter)
      do_request
      expect(assigns(:lesson_header)).to eq(presenter.lesson_header)
    end

    it 'assigns return_url' do
      do_request
      expect(assigns(:return_url)).to eq(instructor_help_requests_path(@program))
    end

    it 'ensures to load activity with correct cms revision id' do
      expect(activity).to receive(:ensure_correct_version).with(attempt.cms_revision_id)

      do_request
    end

    it 'assigns the correct activity to the loaded attempt' do
      activity.ensure_correct_version(attempt.cms_revision_id)

      expect(attempt).to receive(:activity=).with(activity)
      expect(activity.cms_revision_id).to eq attempt.cms_revision_id

      do_request
    end

    context 'when vocab_list activities' do
      it 'populates vocab groups' do
        media_item = double('MediaItem', base_dir: '/some_dir', unzipped_directory: '/unzipped_directory',
                                         csv_content: 'csv_content')
        allow(MediaItem).to receive(:find).and_return(media_item)
        group = double('Group', populate_content_from_csv: true, id: 500, base_dir: '', public_dir: '')
        content = double('ContentObject', activity_type: 'vocab_list', groups: [group], has_rubric?: false)
        allow(activity).to receive(:content_object).and_return(content)
        expect(group).to receive(:base_dir=).with('/some_dir')
        expect(group).to receive(:public_dir=).with('/unzipped_directory')
        expect(group).to receive(:content_csv=).with('csv_content')
        expect(group).to receive(:populate_content_from_csv)
        do_request
      end
    end
  end
end
