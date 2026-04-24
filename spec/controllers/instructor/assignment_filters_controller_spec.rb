describe Instructor::AssignmentFiltersController do
  include RspecJsApiHelpers

  def assignment_filter_params
    {
      'previous_section_id' => '',
      'lesson_id' => '',
      'content_type' => 'Activities',
      'activity_type' => '',
      'grading_method' => ''
    }
  end

  def do_request
    get :update, params: {
      program_id: program.id,
      assignment_filter: assignment_filter_params
    }
  end

  describe 'create_or_update' do
    let(:program) { create(:program) }
    let(:instructor) { create(:institution_admin) }
    let(:student) { create(:student) }
    let(:course) { create(:course, program:, owner: instructor) }
    let(:section) { create(:section, course:) }
    let(:enterprise_course) { create(:enterprise_course, program:, owner: instructor) }
    let(:section_2) { create(:section, course: enterprise_course) }
    let(:focus) { instance_double(Focus) }

    before do
      allow(controller).to receive(:current_user).and_return(instructor)
      allow(controller).to receive(:current_focus).and_return(focus)
      allow(focus).to receive(:students).and_return([student])
      allow(controller).to receive(:current_program).and_return(program)
      initialize_program_access_client_calls_for_instructor(instructor, program)
      fake_login(instructor)
    end

    context 'when course is not enterprise' do
      before do
        allow(focus).to receive(:course).and_return(course)
        allow(focus).to receive(:sections).and_return([section])
      end

      it 'redirects to instructor new assignments path' do
        do_request
        expect(response).to redirect_to instructor_new_assignments_path(program.id)
      end
    end

    context 'when course is enterprise' do
      before do
        allow(focus).to receive(:course).and_return(enterprise_course)
        allow(focus).to receive(:section).and_return(section_2)
        allow(focus).to receive(:sections).and_return([section_2])
      end

      it 'redirects to institution admin new assignments template path' do
        do_request
        expect(response).to redirect_to institution_admin_new_assignment_template_path(
          program.id, enterprise_course.id, section_2.id
        )
      end
    end
  end
end
