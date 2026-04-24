require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Lti::InstructorDashboardController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:platform) { create(:lti_rostering_platform, school: school) }
  let(:section) { create(:section, course: course, instructor: instructor) }

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
      get lti_instructor_dashboard_path(default_params.merge(extra_params))
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'raises a 404 error if no Section record exists with the ' \
         'specified guid' do
        expect { do_request(section_guid: 'invalid') }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find Section"
        )
      end

      context 'with a valid section_guid,' do
        it 'displays the instructor dashboard with ' \
           'focus on the specified section' do
          Timecop.freeze(Time.now.utc) do
            other_course = create(
              :course,
              owner: instructor,
              program: program,
              school: school
            )
            create(:section, course: other_course, instructor: instructor)

            do_request

            expect(response).to be_ok
            # Verify that the focus is set to the course and section.
            current_focus = session[:focus][program.id.to_s]
            expect(current_focus['course_id']).to eq(course.id)
            expect(current_focus['section_id']).to eq(section.id)
          end
        end
      end
    end
  end
end
