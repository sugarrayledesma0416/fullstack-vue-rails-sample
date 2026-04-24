describe Instructor::AssessmentTimeLimitsController do
  describe '#index' do
    let(:instructor) { build_stubbed(:instructor) }
    let(:program) { build_stubbed(:program) }
    let(:course) { build_stubbed(:course, owner: instructor, program: program) }
    let(:section) { build_stubbed(:section, course: course) }
    let(:section_focus) do
      Focus.new(
        instructor,
        program,
        program.id.to_s => { 'section_id' => section.id }
      )
    end
    let(:course_focus) do
      Focus.new(
        instructor,
        program,
        program.id.to_s => { 'course_id' => course.id }
      )
    end
    let(:presenter) { double(StudentTimeLimitsPresenter, student_time_limit_index: []) }

    def do_request
      get :index, params: { program_id: program.id, section_id: section.id, activity_id: 123 }
    end

    before do
      fake_login(instructor)
      allow(Section).to receive(:find_by_id).and_return(section)
      allow(Section).to receive(:find).and_return(section)
      allow(section).to receive(:program).and_return(program)
      allow(controller).to receive(:current_program).and_return(program)
      allow(controller).to receive(:current_user).and_return(instructor)
      allow(controller).to receive(:require_program_access).and_return(true)
      allow(StudentTimeLimitsPresenter).to receive(:new).and_return(presenter)
      allow(section_focus).to receive(:students).and_return([])
    end

    it 'requires a section level focus' do
      allow(controller).to receive(:set_current_focus).and_return(section_focus)
      allow(controller).to receive(:current_focus).and_return(section_focus)
      response = do_request
      expect(response).to_not be_redirect
    end

    it 'redirects when focused at the course level' do
      allow(controller).to receive(:current_focus).and_return(course_focus)
      response = do_request
      expect(response).to redirect_to(instructor_assessments_path)
    end
  end
end
