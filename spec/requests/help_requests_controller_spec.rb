require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe HelpRequestsController, type: :request do
  describe 'POST /create' do
    let(:user) { create(:user) }
    let(:program) { create(:program_with_lessons_and_resource_units) }
    let(:course) { create(:course, program:, allows_help_requests: true) }
    let(:section) { create(:section, course:) }
    let(:strand) { create(:toc_entry) }
    let(:lesson) { program.lessons.first }
    let(:activity) do
      create(
        :activity,
        cms_activity_id: 234,
        cms_revision_id: 345,
        lesson:,
        submittable: false,
        toc_location: strand.location,
        concept: create(
          :concept,
          id: strand.location,
          lesson:,
          program:
        )
      )
    end
    let(:notifier) { instance_double(Notifier) }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
    let(:request_params) do
      {
        action: 'show',
        controller: 'activities',
        section_id: section.id.to_s,
        id: activity.id.to_s
      }
    end

    # params that are posted outside of the help_request_data subkey.
    let(:base_params) do
      {
        flash_version: '1.2.3',
        helpable_item_id: 'reference_02',
        helpable_item_type: 'reference',
        request_type: 'request_help',
        severity_level: 2,
        student_comment: 'blah'
      }
    end

    # params posted inside the help_request_data subkey
    let(:help_request_data_params) do
      {
        activity_id: activity.id,
        activity_state: 'show',
        cms_activity_id: activity.cms_activity_id,
        cms_revision_id: activity.cms_revision_id,
        http_referer: '/valid/referer',
        section_id: section.id
      }
    end

    let(:browser_version) { '77.0.3865.75' }
    let(:user_agent_string) do
      'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 ' \
      "(KHTML, like Gecko) Chrome/#{browser_version} Safari/537.36"
    end

    let(:valid_params) do
      base_params.merge(
        help_request_data: help_request_data_params.merge(
          request_params:
        )
      )
    end

    let(:user_agent_headers) do
      {
        'HTTP_USER_AGENT' => user_agent_string,
        'USER_AGENT' => user_agent_string
      }
    end

    before do
      create(
        :attempt_completed,
        activity_id: activity.id,
        section_id: section.id,
        user_id: user.id
      )
      allow(Notifier).to receive(:problem_report).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_now)
    end

    def do_request
      post(help_requests_path, params: valid_params, headers: user_agent_headers)
    end

    include_examples 'require logged in user'

    context 'with a logged in student,' do
      before do
        create(:enrollment, user:, section:)

        log_in_user(user)
      end

      it 'requires a root key :help_request_data in the params' do
        expect { post(help_requests_path, params: {}) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: help_request_data/
        )
      end

      it 'creates a new help request' do
        do_request

        expect(response).not_to redirect_to(%r{/login})

        expect(response).to be_ok

        new_request = HelpRequest.last
        expect(new_request).to have_attributes(base_params)
        expect(new_request).to have_attributes(help_request_data_params)
        # validate attributes extracted from request_env
        expect(new_request).to have_attributes(
          browser_name: 'Chrome',
          browser_version: browser_version,
          ip_address: '127.0.0.1',
          operating_system: 'Windows 7',
          user_agent_string: user_agent_string
        )
        # request_params are posted as a hash but transformed to a string
        # in the database.
        # user_id is posted as an array of user_ids but transformmed to a
        # single attribute.
        expect(new_request).to have_attributes(
          request_params: request_params.stringify_keys.to_s,
          user_id: user.id
        )
      end
    end

    context 'with a logged in instructor,' do
      let(:instructor) { create(:instructor) }

      before do
        create(:section_instructor, section:, user_id: instructor.id)
        log_in_user(instructor)
      end

      it 'creates a new content problem report' do
        instructor_params = valid_params.deep_merge(
          help_request_data: {
            request_params: { section_id: 0 },
            program_id: program.id,
            section_id: 0,
            user_id: [instructor.id]
          },
          request_type: 'report_content_problem'
        )

        post(help_requests_path, params: instructor_params, headers: user_agent_headers)

        expect(response).to be_ok

        new_request = HelpRequest.last
        expect(new_request).to have_attributes(
          request_type: 'report_content_problem',
          section_id: 0,
          user_id: instructor.id
        )
      end
    end
  end
end
