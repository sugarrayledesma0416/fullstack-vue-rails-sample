require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Lti::StudentDashboardController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:platform) { create(:lti_rostering_platform, school: school) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:student) { create(:student) }

  let(:launch) do
    create(:lti_launch, decoded_jwt: { 'iss' => platform.issuer_id })
  end

  let(:course) do
    create(:course, owner: instructor, program: program, school: school)
  end

  describe 'GET /dashboard' do
    let(:default_params) do
      {
        launch_guid: launch.guid,
        section_guid: section.guid,
        program_id: program.id
      }
    end

    def do_request(extra_params = {})
      get lti_student_dashboard_path(default_params.merge(extra_params))
    end

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end
      
      it 'raises a 404 error if no Section record exists with the ' \
         'specified guid' do
        expect { do_request(section_guid: 'invalid') }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find Section"
        )
      end

      context 'with a valid section_guid,' do
        it 'redirects to the student course dashboard' do
           do_request
            expect(response).to redirect_to(
              course_section_path(
                course_id: course.id,
                section_id: section.id
              )
            )
        end
      end
    end
  end
end
