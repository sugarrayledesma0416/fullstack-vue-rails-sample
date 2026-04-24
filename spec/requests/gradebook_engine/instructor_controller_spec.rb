require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe GradebookEngine::InstructorController do
  # The Instructor controller inside the GradebookEngine relies on some
  # dependency injection from M3. These tests exercise the connections
  # between the two codebases. They use one selected controller class
  # that inherits from GradebookEngine::InstructorController, which
  # should be representative of the behaviour of all the sibling classes.
  let(:owner) { create(:instructor) }
  let(:co_instructor) { create(:instructor) }
  let(:assistant) { create(:instructor) }
  let(:non_team_member) { create(:instructor) }
  let(:program) { create(:program) }
  let(:course) { create(:course, owner: owner, program: program) }

  let!(:section) { create(:section, course: course, instructor: owner) }

  # This route needs to be calculated before the tests run, otherwise the
  # gradebook engine routes somehow mess up the path helpers.
  let!(:dashboard) { instructor_dashboard_path(program_id: program.id) }

  let(:expected_redirect) do
    gradebook_engine.course_section_scores_url(
      course_id: course.id,
      program_id: program.id,
      section_id: section.id
    )
  end

  describe 'GET /show', new_gb_sync: true do
    let(:target_path) do
      gradebook_engine.course_path(course_id: course.id, program_id: program.id)
    end

    def do_request
      get(target_path)
    end

    include_examples 'require instructor with program access'

    context 'when there is no section_id param,' do
      let(:course_access_error) do
        'This page requires instructor access to the current course.'
      end

      it 'allows access to the course owner' do
        log_in_user_with_access_to_programs(owner, [program])
        do_request

        expect(flash[:error]).to be_blank
        expect(response).to redirect_to(expected_redirect)
      end

      it 'allows access to co-instructors of any section in the course' do
        create(:section_co_instructor, section: section, instructor: co_instructor)

        # Create additional section in the course, to which co-instructor
        # does not have access.
        create(:section, course: course, instructor: owner)

        log_in_user_with_access_to_programs(co_instructor, [program])
        do_request

        expect(flash[:error]).to be_blank
        expect(response).to redirect_to(expected_redirect)
      end

      it 'allows access to assistants of any section in the course' do
        create(:section_assistant, section: section, instructor: assistant)

        # Create additional section in the course, to which assistant
        # does not have access.
        create(:section, course: course, instructor: owner)

        log_in_user_with_access_to_programs(assistant, [program])
        do_request

        expect(flash[:error]).to be_blank
        expect(response).to redirect_to(expected_redirect)
      end

      it 'denies access to instructors who are neither course owner, ' \
         'co-instructor, or assistant' do
        log_in_user_with_access_to_programs(non_team_member, [program])
        do_request

        expect(flash[:error]).to eq(course_access_error)
        expect(response).to redirect_to(dashboard)
      end
    end

    context 'when there is a section_id param,' do
      let(:other_section) { create(:section, course: course, instructor: owner) }

      let(:section_access_error) do
        'This page requires instructor access to the current section.'
      end

      let(:section_path) do
        gradebook_engine.course_path(
          course_id: course.id,
          program_id: program.id,
          section_id: section.id
        )
      end

      let(:other_section_path) do
        gradebook_engine.course_path(
          course_id: course.id,
          program_id: program.id,
          section_id: other_section.id
        )
      end

      it 'allows access to the course owner' do
        log_in_user_with_access_to_programs(owner, [program])
        get(section_path)

        expect(flash[:error]).to be_blank
        expect(response).to redirect_to(expected_redirect)
      end

      it 'allows access to co-instructors for the specified section id' do
        create(:section_co_instructor, section: section, instructor: co_instructor)

        log_in_user_with_access_to_programs(co_instructor, [program])
        get(section_path)

        expect(flash[:error]).to be_blank
        expect(response).to redirect_to(expected_redirect)

        get(other_section_path)

        expect(flash[:error]).to eq(section_access_error)
        expect(response).to redirect_to(dashboard)
      end

      it 'allows access to assistants for the specified section id' do
        create(:section_assistant, section: section, instructor: assistant)

        log_in_user_with_access_to_programs(assistant, [program])
        get(section_path)

        expect(flash[:error]).to be_blank
        expect(response).to redirect_to(expected_redirect)

        get(other_section_path)

        expect(flash[:error]).to eq(section_access_error)
        expect(response).to redirect_to(dashboard)
      end

      it 'denies access to instructors who are neither course owner, ' \
         'co-instructor, or assistant' do
        log_in_user_with_access_to_programs(non_team_member, [program])
        get(section_path)

        expect(flash[:error]).to eq(section_access_error)
        expect(response).to redirect_to(dashboard)
      end
    end
  end
end
