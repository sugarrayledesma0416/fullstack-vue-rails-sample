require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Cartridge::LaunchesController do
  let(:school) { create(:school) }
  let(:program) { create(:program_with_lessons) }
  # Activity
  let(:activity) { create(:activity, lesson: program.lessons.first) }
  let!(:activity_resource_link) { create(:cartridge_resource_link, resource_id: activity.id) }
  # Activity with type link_vtext
  let(:link_vtext_activity) { create(:activity, activity_type: 'link_vtext') }
  let(:link_vtext_activity_link) do
    '//reader.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2?rid=977211&page=12'
  end
  let(:link_vtext_activity_resource_link) do
    create(:cartridge_resource_link, resource_id: link_vtext_activity.id, resource_type: 'activity')
  end
  # Resource
  let(:resource) { create(:resource, program: program) }
  let(:expected_signed_url) { 'http://example.com/signed_url' }
  let!(:downloadable_resource_resource_link) do
    create(:cartridge_resource_link, resource_id: resource.id, resource_type: 'resource')
  end
  # vText instructor
  let(:instructor_dsl_reader_link) do
    '//reader.vhlcentral.com/portales1e/teacher-edition/vol1_ecompanion-v2'
  end
  let(:instructor_vtext_resource_link) do
    create(:cartridge_resource_link, resource_id: program.id, resource_type: 'instructor_vtext')
  end
  # vText student
  let(:student_dsl_reader_link) do
    '//reader.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2_vtext'
  end
  let(:student_ecompanion_reader_link) do
    '//reader.vhlcentral.com/portales1e/ecompanion/vol1_ecompanion-v2_ecompanion'
  end
  let(:student_vtext_resource_link) do
    create(:cartridge_resource_link, resource_id: program.id, resource_type: 'student_vtext')
  end

  # Activity in different program, same context_id
  let(:diff_program) { create(:program_with_lessons) }
  let(:diff_activity) { create(:activity, lesson: diff_program.lessons.first) }
  let!(:diff_activity_resource_link) { create(:cartridge_resource_link, resource_id: diff_activity.id) }

  let(:instructor) { create(:cartridge_instructor_user_link, school: school).user }
  let(:student) { create(:cartridge_student_user_link, school: school).user }

  # legacy launch (CC 1.1) params
  let!(:consumer) { create(:cartridge_consumer, school: school) }
  let!(:lms_context_id) { SecureRandom.uuid }
  let(:default_params) do
    {
      consumer_guid: consumer.guid,
      context_id: lms_context_id,
      context_label: 'Context label',
      context_title: 'Context title',
      launch_presentation_return_url: 'www.lms.example.com',
      lis_outcome_service_url: 'MyLisOutcomeServiceUrl',
      lis_result_sourcedid: SecureRandom.uuid,
      lti_version: '1.1.0',
      resource_link_id: activity_resource_link.resource_link_id
    }
  end

  let(:diff_program_params) do
    {
      resource_link_id: diff_activity_resource_link.resource_link_id,
      consumer_guid: consumer.guid,
      context_id: lms_context_id,
      context_label: 'Diff Program Context label',
      context_title: 'Diff Program Context title',
      launch_presentation_return_url: 'www.lms.example.com',
      lis_outcome_service_url: 'MyLisOutcomeServiceUrl',
      lis_result_sourcedid: SecureRandom.uuid,
      lti_version: '1.1.0'
    }
  end
  # new launch (CC 1.3) params
  let(:lti_platform) { create(:lti_platform, school: school, cartridge: true) }
  let(:line_items_url) { "https://lms.example.org/api/lti/courses/#{SecureRandom.uuid}" }
  let(:line_item_url) { "#{line_items_url}/line_item/#{rand(1..99)}" }
  let(:default_params_cc_1_3_0) do
    {
      context_id: SecureRandom.uuid,
      context_label: 'Context label',
      context_title: 'Context title',
      launch_presentation_return_url: 'MyLaunchPresentationReturnUrl',
      line_items_url: line_items_url,
      line_item_url: line_item_url,
      lti_version: '1.3.0',
      platform_guid: lti_platform.guid,
      resource_link_id: activity_resource_link.resource_link_id
    }
  end

  let(:grant_results) do
    {
      'errors' => [],
      'use_site_license' => true,
      'results' => {
        'normal' => [],
        'soft' => [],
        'hard' => []
      }
    }
  end
  let(:revoke_results) { { 'rollback_id' => 1, 'errors' => [] } }
  let(:course_access) do
    instance_double(Maestro::CourseAccess,
                    enough_for_course_duration?: true,
                    enough_for_today?: true)
  end
  let(:available_course_package_ids) { [99] }

  def encode_params(params)
    { launch_params: (JWT.encode params, 'secret1', 'HS256') }
  end

  before do
    create(:cartridge_contexts_owner, school: school)
    allow(CourseLicenseCreatorWorker).to receive(:perform_async)
    allow_any_instance_of(CourseOptions).to receive(:available_course_package_ids)
      .and_return(available_course_package_ids)
    allow(Maestro::User).to receive(:grant_multiple_site_license_seats)
      .and_return(grant_results)
    allow(Maestro::CourseAccess).to receive(:find_for_user_and_course)
      .and_return(course_access)
    allow(Maestro::User).to receive(:revoke_site_license_seat).and_return(revoke_results)
    allow_any_instance_of(Resource).to receive(:signed_url).and_return(expected_signed_url)
    allow_any_instance_of(VtextLinker).to receive(:link).and_return(link_vtext_activity_link)
    allow_any_instance_of(ProgramSettings).to receive(:vtext_link)
      .and_return(student_dsl_reader_link)
    allow_any_instance_of(ProgramSettings).to receive(:teacher_vtext_link)
      .and_return(instructor_dsl_reader_link)
    allow(HTTP_AUTHENTICATIONS).to receive(:values).and_return(["secret", "secret1", "secret2"])
    allow(Maestro::CourseLicense).to receive(:all).and_return([instance_double(Maestro::CourseLicense)])
    allow(Maestro::Enrollment).to receive(:check_licenses).and_return('enrollment_guids' => [])
    allow(Maestro::User).to receive(:ensure_instructor_access_matches_site_license)
  end

  describe 'GET /show' do
    def target_path
      cartridge_launch_path(
        resource_link_id: activity_resource_link.resource_link_id
      )
    end

    def do_request(params = {})
      get target_path, params: params
    end

    include_examples 'require logged in user'

    shared_examples 'redirects' do
      context 'when the resource link id is an activity' do
        it 'redirects the instructor to the activity page' do
          do_request(encode_params(default_params))

          expect(response).to redirect_to(
            cartridge_section_activity_path(
              session[:cartridge][:current_section_id],
              activity.id
            )
          )
        end
      end

      context 'when the resource link id is an activity with type link_vtext' do
        it 'redirects the instructor to the vtext link with the number page' do
          get cartridge_launch_path(
            resource_link_id: link_vtext_activity_resource_link.resource_link_id
          ), params: encode_params(default_params)

          expect(response).to redirect_to(link_vtext_activity_link)
        end
      end
    end

    shared_examples 'requires a valid lti_version' do
      context 'when launch_presentation_return_url is not present' do
        it 'redirects the user to the shared cartridge error page' do
          do_request(encode_params(default_params.except(:launch_presentation_return_url)))

          expect(response).to be_bad_request
          expect(response).to render_template('cartridge/shared/error')
          expect(assigns(:errors)).to match(
            lti_version: 'LTI version missing or not supported'
          )
        end
      end

      context 'when launch_presentation_return_url is present' do
        it 'redirects the user to the launch page' do
          do_request(encode_params(default_params))

          expect(response).to redirect_to(
            URI(default_params[:launch_presentation_return_url]).tap do |uri|
              uri.query = { lti_errormsg: 'LTI version missing or not supported' }.to_query
            end.to_s
          )
        end
      end
    end

    context 'with a valid logged-in student,' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      context 'when the resource link id is a resource' do
        it 'redirects the student to the downloadable resource link' do
          resource.update(vhl_student_resource: true)
          default_params[:resource_link_id] = downloadable_resource_resource_link.resource_link_id
          get cartridge_launch_path(
            resource_link_id: downloadable_resource_resource_link.resource_link_id
          ), params: encode_params(default_params)

          expect(response).to redirect_to(expected_signed_url)
        end
      end

      context 'when the resource link id is a student_vtext' do
        it 'redirects the student to the vtext link' do
          default_params[:resource_link_id] = student_vtext_resource_link.resource_link_id

          get cartridge_launch_path(
            resource_link_id: student_vtext_resource_link.resource_link_id
          ), params: encode_params(default_params)

          expect(response).to redirect_to(student_ecompanion_reader_link)
        end
      end

      include_examples 'redirects'
    end

    context 'with a valid logged-in instructor,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      context 'when the resource link id is a resource' do
        it 'redirects the instructor to the downloadable resource link' do
          default_params[:resource_link_id] = downloadable_resource_resource_link.resource_link_id

          get cartridge_launch_path(
            resource_link_id: downloadable_resource_resource_link.resource_link_id
          ), params: encode_params(default_params)

          expect(response).to redirect_to(expected_signed_url)
        end
      end

      context 'when the resource link id is a instructor_vtext' do
        it 'redirects the instructor to the vtext link' do
          default_params[:resource_link_id] = instructor_vtext_resource_link.resource_link_id

          get cartridge_launch_path(
            resource_link_id: instructor_vtext_resource_link.resource_link_id
          ), params: encode_params(default_params)

          expect(response).to redirect_to(instructor_dsl_reader_link)
        end
      end

      include_examples 'redirects'
    end

    context 'when there are no errors' do

      let(:section) do
        Cartridge::CourseContextDetail.find_by(
          lms_context_id: default_params[:context_id],
          school: school,
          program_id: program.id
        ).section
      end

      before do
        log_in_user_with_access_to_programs(student, [program])
        do_request(encode_params(default_params))
      end

      context 'when the launch is a legacy CC 1.1 launch' do
        it 'saves the consumer guid, section id and LTI version in the session cartridge' do
          expect(session[:cartridge]).to include(
            consumer_guid: default_params[:consumer_guid],
            current_section_id: section.id,
            lti_version: '1.1.0'
          )
        end

        it 'does not save the platform guid in the session cartridge' do
          expect(session[:cartridge]).not_to include(:platform_guid)
        end
      end

      context 'when the launch is a CC 1.3 launch' do
        let(:default_params) { default_params_cc_1_3_0 }

        it 'saves the platform guid, section id and LTI version in the session cartridge' do
          expect(session[:cartridge]).to include(
            platform_guid: default_params[:platform_guid],
            current_section_id: section.id,
            lti_version: '1.3.0'
          )
        end

        it 'does not save the consumer guid in the session cartridge' do
          expect(session[:cartridge]).not_to include(:consumer_guid)
        end
      end

      it 'saves information about the program, section and course in the session focus' do
        expect(session[:focus]).to include(
          section.course.program_id.to_s => {
            section_id: section.id,
            course_id: section.course.id
          }
        )
      end
    end

    context 'when there is more than one section for the same context id' do
      let!(:course) { create(:course, owner: instructor, school: school) }
      let!(:section) { create(:section, course: course, instructor: instructor, program: program) }
      let!(:course_context_detail) do
        create(
          :cartridge_course_context_detail,
          section_id: section.id,
          course_id: course.id,
          lms_context_id: lms_context_id,
          school: school,
          program_id: program.id
        )
      end

      let(:diff_prog_section) do
        Cartridge::CourseContextDetail.find_by(
          lms_context_id: diff_program_params[:context_id],
          school: school,
          program_id: diff_program.id
        ).section
      end

      before do
        log_in_user_with_access_to_programs(instructor, [diff_program])
        get cartridge_launch_path(
              resource_link_id: diff_activity_resource_link.resource_link_id
            ), params: encode_params(diff_program_params)
      end

      it 'saves the section and school id in the session cartridge' do
        expect(session[:cartridge]).to include(
                                         consumer_guid: diff_program_params[:consumer_guid],
                                         current_section_id: diff_prog_section.id
                                       )
      end

      it 'saves information about the program, section and course in the session focus' do
        expect(session[:focus]).to include(
                                     diff_prog_section.course.program_id.to_s => {
                                       section_id: diff_prog_section.id,
                                       course_id: diff_prog_section.course.id
                                     }
                                   )
      end
    end

    context 'when there are errors after running the course section creator process' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'does not save the section and school id in the session cartridge' do
        do_request(encode_params(default_params.except(:context_id)))
        expect(session[:cartridge]).to be_nil
      end

      it 'does not save information about the program, section and course in the session focus' do
        do_request(encode_params(default_params.except(:context_id)))
        expect(session[:focus]).to be_nil
      end

      it 'redirects the user to the errors page if the parameter' \
        'launch_presentation_return_url is nil' do
        default_params[:launch_presentation_return_url] = nil
        do_request(encode_params(default_params.except(:context_id)))

        expect(response).to be_bad_request
        expect(response).to render_template('cartridge/shared/error')
        expect(assigns(:errors)).to match(
          section: 'Section Context title could not be created: ' \
          'Cartridge course context detail lms context is required'
        )
      end

      it 'redirects the user to the launch page if the parameter' \
        'launch_presentation_return_url is present' do
        do_request(encode_params(default_params.except(:context_id)))

        expect(response).to redirect_to(
          URI(default_params[:launch_presentation_return_url]).tap do |uri|
            uri.query = { lti_errormsg: 'Something wrong happened' }.to_query
          end.to_s
        )
      end
    end

    context 'when the resource link does not exist in the database' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'redirects the user to the error page if the parameter' \
        'launch_presentation_return_url is nil' do
        default_params[:launch_presentation_return_url] = nil
        default_params[:resource_link_id] = '1'
        get cartridge_launch_path(resource_link_id: '1'), params: encode_params(default_params)

        expect(response).to be_bad_request
        expect(response).to render_template('cartridge/shared/error')
        expect(assigns(:errors)).to match(
          resource_link: 'Resource link does not exist'
        )
      end

      it 'redirects the user to the launch page if the parameter' \
        'launch_presentation_return_url is present' do
        default_params[:resource_link_id] = '1'
        get cartridge_launch_path(resource_link_id: '1'), params: encode_params(default_params)

        expect(response).to redirect_to(
          URI(default_params[:launch_presentation_return_url]).tap do |uri|
            uri.query = { lti_errormsg: 'Resource link does not exist' }.to_query
          end.to_s
        )
      end
    end

    context 'when the LTI version is invalid' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      context 'when lti_version is not present' do
        before do
          default_params[:lti_version] = nil
        end

        include_examples 'requires a valid lti_version'
      end

      context 'when lti_version is not included in supported versions' do
        before do
          default_params[:lti_version] = '1.2.0'
        end

        include_examples 'requires a valid lti_version'
      end
    end

    context 'when a course is closed' do
      let(:course) { create(:closed_course, is_archived: true, program: program, school: school) }
      let(:section) { create(:section, is_archived: true, course: course) }
      let(:cartridge_course_context_detail) do
        create(
          :cartridge_course_context_detail,
          is_archived: true,
          course: course,
          section: section,
          school: school,
          program_id: program.id
        )
      end

      before do
        default_params[:context_id] = cartridge_course_context_detail.lms_context_id
      end

      context 'when an instructor checks the course' do
        before do
          log_in_user_with_access_to_programs(instructor, [program])
        end

        it 'sets the closed course error message' do
          do_request(encode_params(default_params))
          expect(assigns(:message)).to match(
            'The course you are trying to access has been closed in VHLCentral' \
            ' and is no longer available.'
          )
        end

        it 'renders the closed course view' do
          do_request(encode_params(default_params))
          expect(response).to render_template('cartridge/launches/closed_course')
        end

        context 'when the error is related to something other than a closed course' do
          before do
            allow_any_instance_of(Cartridge::CourseSectionCreator).to receive(:success).and_return(false)
            default_params[:context_id] = nil
            default_params[:launch_presentation_return_url] = nil
          end

          it 'renders the default error template' do
            do_request(encode_params(default_params))

            expect(response).to render_template('cartridge/shared/error')
            expect(assigns(:errors)).not_to include(:closed_course)
          end
        end
      end

      context 'when an student checks the course' do
        before do
          log_in_user_with_access_to_programs(student, [program])
        end

        it 'sets the closed course error message' do
          do_request(encode_params(default_params))
          expect(assigns(:message)).to match(
            'The course you are trying to access has been closed in VHLCentral' \
            ' and is no longer available.'
          )
        end

        it 'renders the closed course view' do
          do_request(encode_params(default_params))
          expect(response).to render_template('cartridge/launches/closed_course')
        end

        context 'when the error is related to something other than a closed course' do
          before do
            allow_any_instance_of(Cartridge::CourseSectionCreator).to receive(:success).and_return(false)
            default_params[:context_id] = nil
            default_params[:launch_presentation_return_url] = nil
          end

          it 'renders the default error template' do
            do_request(encode_params(default_params))

            expect(response).to render_template('cartridge/shared/error')
            expect(assigns(:errors)).not_to include(:closed_course)
          end
        end
      end
    end
  end
end
