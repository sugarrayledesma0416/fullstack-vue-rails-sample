require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Lti::DeepLinkSessionsController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:platform) { create(:lti_platform) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  let(:launch) do
    create(:lti_launch, decoded_jwt: { 'iss' => platform.issuer_id })
  end

  let(:course) do
    create(:course, owner: instructor, program: program, school: school)
  end

  describe 'GET /init' do
    let(:default_params) do
      {
        launch_guid: launch.guid,
        section_guid: section.guid,
        program_id: program.id
      }
    end

    def do_request(extra_params = {})
      get lti_deep_link_session_init_path(default_params.merge(extra_params))
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'raises a 404 error if no Lti::Launch record exists with the ' \
         'specified guid' do
        expect { do_request(launch_guid: 'invalid') }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find Lti::Launch"
        )
      end

      it 'raises a 404 error if no Section record exists with the ' \
         'specified guid' do
        expect { do_request(section_guid: 'invalid') }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find Section"
        )
      end

      context 'with a valid launch_guid and section_guid,' do
        it 'sets the deep linking information in the session, sets the ' \
           'focus to the specified section, and redirects ' \
           'to the instructor table of contents' do
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

            expect(response).to render_template(:init)

            expect(session[:lti_deep_link_launch_guid]).to eq(launch.guid)
            expect(
              Time.at(session[:lti_launch_expiration]).utc
            ).to be_within(3.seconds).of(1.hour.from_now)

            # Verify that the focus is set to the course and section.
            current_focus = session[:focus][program.id.to_s]
            expect(current_focus['course_id']).to eq(course.id)
            expect(current_focus['section_id']).to eq(section.id)

            expect(assigns(:launch)).to eq(launch)
          end
        end
      end
    end
  end

  describe 'GET /terminate' do
    let(:return_to_url) { "/resources/programs/#{program.id}" }
    let(:default_params) do
      { program_id: program.id, return_to: return_to_url }
    end

    def do_request(extra_params = {})
      get lti_terminate_deep_link_session_path(default_params.merge(extra_params))
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'clears the deep link session info and redirects to the return_to url' do
        do_request

        expect(response).to redirect_to(return_to_url)

        expect(session[:lti_deep_link_launch_guid]).to be_nil
        expect(
          Time.at(session[:lti_launch_expiration]).utc
        ).to be_within(3.seconds).of(1.second.ago.utc)
      end
    end
  end
end
