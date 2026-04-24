require 'requests/login_helper_methods'

describe Ua::Lti::LaunchesController do
  let(:school) { create(:school) }
  let(:program) { create(:program_with_lessons) }
  let!(:instructor) { create(:lti_rostering_instructor, schools: [school]) }
  let!(:non_rostering_instructor) { create(:instructor, schools: [school]) }
  let!(:lti_platform) { create(:lti_rostering_platform) }
  let!(:linked_instructor) { create(:lti_user_link, user: instructor, lti_platform: lti_platform) }
  let(:student) { create(:user) }
  let!(:existing_context_id) { SecureRandom.uuid }
  let(:random_guid) { SecureRandom.uuid }
  let(:default_params) do
    {
      context_id: SecureRandom.uuid,
      context_label: 'Context label',
      context_title: 'Context title',
      lti_platform_guid: lti_platform.guid,
      school_guid: school.guid,
      user_guid: instructor.guid
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
  let(:available_course_packages) { [{ id: 99 }] }

  let(:valid_username) { 'maestro' }
  let(:valid_password) { 'test' }
  let(:basic_auth_klass) { ActionController::HttpAuthentication::Basic }
  let(:valid_auth_headers) { auth_headers(valid_username, valid_password) }

  def auth_headers(username, password)
    credentials = basic_auth_klass.encode_credentials(username, password)
    { 'HTTP_AUTHORIZATION' => credentials }
  end

  def create_linked_section(owner)
    section = create(:section_with_course, instructor: owner)
    create(:lti_context_link,
           section_id: section.id,
           context_id: existing_context_id,
           lti_platform: lti_platform
    )
    section
  end

  def parse_response(response, element)
    JSON.parse(response.body).symbolize_keys[element]
  end

  before do
    allow(CourseLicenseCreatorWorker).to receive(:perform_async)
    allow_any_instance_of(CourseOptions).to receive(:available_course_packages)
      .and_return(available_course_packages)
    allow(Maestro::User).to receive(:grant_multiple_site_license_seats)
                              .and_return(grant_results)
    allow(Maestro::CourseAccess).to receive(:find_for_user_and_course)
                                      .and_return(course_access)
    allow(Maestro::User).to receive(:revoke_site_license_seat).and_return(revoke_results)
    allow(HTTP_AUTHENTICATIONS).to receive(:values).and_return(%w[secret secret1 secret2])
    allow(Maestro::CourseLicense).to receive(:all).and_return([instance_double(Maestro::CourseLicense)])
    allow(Maestro::Enrollment).to receive(:check_licenses).and_return('enrollment_guids' => [])
    allow(Maestro::User).to receive(:ensure_instructor_access_matches_site_license)
    stub_const('HTTP_AUTHENTICATIONS', valid_username => valid_password)
  end

  describe 'POST /context' do
    def target_path
      context_ua_lti_launch_path(
        program_id: program.id
      )
    end

    def do_request(params = {})
      post target_path, params: params, headers: valid_auth_headers
    end

    context 'when there are no errors during the creation launch' do
      it 'returns the guid of the newly created section' do
        enable_dangerfield do
          expect do
            do_request(default_params)
          end.to change(Section, :count).by(1)
          expect(response).to be_ok
          expect(parse_response(response, :section_guid)).to eq(Section.last.guid)
        end
      end

      it 'returns the guid of an existing section when there is one' do
        enable_dangerfield do
          section = create_linked_section(instructor)
          expect do
            do_request(default_params.merge(context_id:existing_context_id))
          end.to change(Section, :count).by(0)
          expect(response).to be_ok
          expect(parse_response(response, :section_guid)).to eq(section.guid)
        end
      end
    end

    context 'when the specified user is a non-rostering instructor' do
      before do
        do_request(default_params.merge(user_guid: non_rostering_instructor.guid))
      end

      it 'returns error response' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include(
          "User guid: #{non_rostering_instructor.guid} is not an LTI Rostering instructor"
        )
      end
    end

    context 'when the specified user is not an instructor' do
      before do
        do_request(default_params.merge(user_guid: student.guid))
      end

      it 'returns error response' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include(
          "User guid: #{student.guid} is not an LTI Rostering instructor"
        )
      end
    end

    context 'when the specified user does not exist' do
      before do
        do_request(default_params.merge(user_guid: random_guid))
      end

      it 'returns error response' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include(
          "User guid: #{random_guid} was not found"
        )
      end
    end

    context 'when the request is missing required parameters' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'returns error when request is missing a context id' do
        do_request(default_params.except(:context_id))
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include('param is missing or the value is empty: context_id')
      end

      it 'returns error when request is missing a school_guid' do
        do_request(default_params.except(:school_guid))
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include('param is missing or the value is empty: school_guid')
      end

      it 'returns error when request is missing an lti_platform_guid' do
        do_request(default_params.except(:lti_platform_guid))
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include('param is missing or the value is empty: lti_platform_guid')
      end
    end

    context 'when the UA-linked section is archived here in M3' do
      let(:section) { create_linked_section(instructor) }

      before do
        # Set to archived without callbacks to mimic sync failure.
        section.update_column(:is_archived, true)
        default_params[:section_guid] = section.guid
      end

      it 'returns error response' do
        enable_dangerfield do
          expect do
            do_request(default_params.merge(context_id: existing_context_id))
          end.not_to change(Section, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(parse_response(response, :errors)).to eq({
            'save' => 'Unable to create a new section for LMS context because ' \
                      'the previous section was not successfully deleted.'
          })
        end
      end
    end

    context 'when there are errors after running the course section creator create' do
      before do
        allow_any_instance_of(::Lti::CourseSectionCreator).to receive(:success).and_return(false)
        log_in_user_with_access_to_programs(instructor, [program])
        do_request(default_params)
      end

      it 'returns error when CourseSectionCreator is not successful' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /context' do
    def target_path
      ua_lti_launch_path(
        program_id: program.id
      )
    end

    def do_request(params = {})
      delete target_path, params: params, headers: valid_auth_headers
    end

    context 'when there are no errors during the deletion process' do
      it 'returns the guid of the deleted section' do
        enable_dangerfield do
          section = create_linked_section(instructor)
          section_guid = section.guid
          expect do
            do_request(default_params.merge(context_id:existing_context_id))
          end.to change(Section, :count).by(-1)
          expect(response).to be_ok
          expect(parse_response(response, :section_guid)).to eq(section_guid)
        end
      end
    end

    context 'when the specified user is a non-rostering instructor' do
      before do
        do_request(default_params.merge(user_guid: non_rostering_instructor.guid))
      end

      it 'returns error response' do
        expect(response).to  have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include(
          "User guid: #{non_rostering_instructor.guid} is not an LTI Rostering instructor"
        )
      end
    end

    context 'when the specified user is not an instructor' do
      before do
        do_request(default_params.merge(user_guid: student.guid))
      end

      it 'returns error response' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include(
          "User guid: #{student.guid} is not an LTI Rostering instructor"
        )
      end
    end

    context 'when the specified user does not exist' do
      before do
        do_request(default_params.merge(user_guid: random_guid))
      end

      it 'returns error response' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include(
          "User guid: #{random_guid} was not found"
        )
      end
    end

    context 'when the request is missing required parameters' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'returns error when request is missing a context id' do
        do_request(default_params.except(:context_id))
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include('param is missing or the value is empty: context_id')
      end

      it 'returns error when request is missing an lti_platform_guid' do
        do_request(default_params.except(:lti_platform_guid))
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to include('param is missing or the value is empty: lti_platform_guid')
      end
    end

    context 'when there are errors during the deletion launch' do
      it 'returns an error when the specified Lti::Platform is not found' do
        enable_dangerfield do
          do_request(default_params.merge(lti_platform_guid: SecureRandom.uuid))
          expect(response).to have_http_status(:unprocessable_entity)
          expect(parse_response(response, :errors)).to include("Couldn't find Lti::Platform")
        end
      end

      it 'returns error when the specified Lti::ContextLink link is not found' do
        enable_dangerfield do
          do_request(default_params)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(parse_response(response, :errors)).to include("Couldn't find Lti::ContextLink")
        end
      end
    end

    context 'when there are errors after running the course section creator create' do
      before do
        allow_any_instance_of(SectionArchiver).to receive(:success).and_return(false)
        log_in_user_with_access_to_programs(instructor, [program])
        do_request(default_params)
      end

      it 'returns error when SectionArchiver is not successful' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
