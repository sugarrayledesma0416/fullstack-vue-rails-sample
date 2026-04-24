require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe GradebookEngine::StudentGradesController, new_gb_sync: true do
  # The StudentGrades controller inside the GradebookEngine relies on some
  # dependency injection from M3. These tests exercise the connections
  # between the two codebases. Only one action in the controller needs to
  # be tested in order to validate the behaviour for all similar actions.
  let(:owner) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: owner, program: program) }
  let(:section) { create(:section, course: course, instructor: owner) }

  let(:access_error) do
    'This page requires that the user be either the student with ' \
    'grades to be viewed OR an instructor with access to the section.'
  end

  # This route needs to be calculated before the tests run, otherwise the
  # gradebook engine routes somehow mess up the path helpers.
  let!(:ua_home) { ua_home_path }

  describe 'GET /overview' do
    let(:target_path) do
      gradebook_engine.section_user_summary_path(
        course_id: course.id,
        program_id: program.id,
        section_id: section.id,
        summary_level_id: section.id,
        user_id: student.id
      )
    end

    def do_request
      get(target_path)
    end

    include_examples 'require logged in user'

    it 'allows access to the student specified by the user_id param' do
      log_in_user_with_access_to_programs(student, [program])
      do_request

      expect(flash[:error]).to be_blank
      expect(response).to be_ok
    end

    it 'denies access to a student not specified by the user_id param' do
      other_student = create(:student)
      log_in_user_with_access_to_programs(other_student, [program])
      do_request

      expect(flash[:error]).to eq(access_error)
      expect(response).to redirect_to ua_home
    end
  end
end
