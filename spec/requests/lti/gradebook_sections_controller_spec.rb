require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Lti::GradebookSectionsController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:launch) { create(:lti_launch) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  let(:course) do
    create(:course, owner: instructor, program: program, school: school)
  end

  describe 'GET /sync_settings' do
    let(:default_params) do
      { section_guid: section.guid, program_id: program.id }
    end

    def do_request(extra_params = {})
      get lti_gradebook_section_sync_settings_path(default_params.merge(extra_params))
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'throws an error if no section exists with the specified guid' do
        expect do
          do_request(section_guid: 'invalid guid')
        end.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find Section"
        )
      end

      it 'sets the focus to the section specified by the section guid and ' \
         'redirects to the gradebook lms sync page for that section' do
        do_request

        expect(response).to redirect_to(
          gradebook_engine.course_section_scores_path(
            course_id: course.id,
            open_lms_sync: true,
            program_id: program.id,
            section_id: section.id
          )
        )

        # Verify that the focus is set to the course and section.
        current_focus = session[:focus][program.id.to_s]
        expect(current_focus['course_id']).to eq(course.id)
        expect(current_focus['section_id']).to eq(section.id)
      end
    end
  end
end
