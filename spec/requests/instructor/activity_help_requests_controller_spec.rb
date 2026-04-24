require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::ActivityHelpRequestsController do
  describe 'PUT /update' do
    # minimum viable activity/strand/lesson construction
    let(:strand) { create(:toc_entry) }
    let(:lesson) { create(:lesson, toc_entries: [strand]) }
    let(:activity) do
      create(
        :activity,
        lesson: lesson,
        toc_location: strand.location,
        concept: create(
          :concept,
          id: strand.location,
          lesson: lesson,
          program: program
        )
      )
    end

    let(:program) { create(:program) }
    let(:instructor) { create(:instructor) }
    let(:section) { create(:section, instructor: instructor) }

    let(:help_request) do
      create(
        :help_request,
        activity: activity,
        program: program,
        section_id: section.id
      )
    end

    let(:target_path) do
      instructor_activity_help_request_path(
        activity_id: help_request.activity_id,
        id: help_request.id,
        program_id: program.id
      )
    end
    let(:update_params) do
      {
        instructor_comment: 'here is some help',
        read_by_student: false,
        status: 'responded'
      }
    end

    def do_request
      put(target_path, params: update_params)
    end

    include_examples 'require instructor with program access'

    it 'updates the help request with the specified id' do
      log_in_user_with_access_to_programs(instructor, [program])

      do_request

      expect(response).to be_ok

      help_request.reload
      # verify that the posted params were permitted
      expect(help_request).to have_attributes(update_params)
      # verify non-posted attributes were set in the controller action
      expect(help_request.processed_by).to eq(instructor.id)

      # verify that a notification was dispatched
      expect(
        HelpRequestResponseNotification.where(
          activity_id: activity.id,
          section_id: section.id,
          user_id: help_request.user_id
        )
      ).to exist

      # verify the body is a JSON representation of the updated help request
      expect(JSON.parse(response.body)).to eq(
        JSON.parse(help_request.to_json(HelpRequest::ACTIVITY_JSON_OPTIONS))
      )
    end
  end
end
