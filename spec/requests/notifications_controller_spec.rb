require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe NotificationsController do
  let(:user) { create(:student) }
  let(:program) { create(:program) }
  let(:section) { create(:section) }

  describe 'GET /json_index' do
    let(:strand) { create(:toc_entry) }
    let(:lesson) { create(:lesson, toc_entries: [strand]) }
    let(:announcement) { create(:announcement) }

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

    let!(:dismissed_activity_notification) do
      create(
        :help_request_response_notification,
        activity: activity,
        dismissed_at: Time.now.utc,
        section: section,
        user: user
      )
    end

    let!(:undismissed_activity_notification) do
      create(
        :activity_feedback_notification,
        activity: activity,
        dismissed_at: nil,
        section: section,
        user: user
      )
    end

    let!(:dismissed_announcement_notification) do
      create(
        :announcement_posted_notification,
        announcement: announcement,
        dismissed_at: Time.now.utc,
        section: section,
        user: user
      )
    end

    let!(:undismissed_announcement_notification) do
      create(
        :announcement_posted_notification,
        announcement: announcement,
        dismissed_at: nil,
        section: section,
        user: user
      )
    end

    let(:target_path) do
      json_index_section_notifications_path(section_id: section.id)
    end

    def do_request
      get target_path
    end

    before do
      create(:active_enrollment, section: section, user: user)
    end

    include_examples 'require logged in user'

    context 'with a logged in user,' do
      before { log_in_user(user) }

      it 'returns a json collection of notifications, including type and ' \
         'dismissed status' do
        do_request

        expect(response).to be_ok

        result = JSON.parse(response.body).deep_symbolize_keys

        expect(result[:announcements][:new]).to contain_exactly(
          hash_including(
            class_cancelled: false,
            id: undismissed_announcement_notification.id,
            label: announcement.title,
            language: program.language_code,
            message: '',
            path: undismissed_announcement_notification.path
          )
        )

        expect(result[:announcements][:viewed]).to contain_exactly(
          hash_including(
            class_cancelled: false,
            id: dismissed_announcement_notification.id,
            label: announcement.title,
            language: program.language_code,
            message: '',
            path: dismissed_announcement_notification.path
          )
        )

        expect(result[:notifications][:new]).to contain_exactly(
          hash_including(
            class_cancelled: false,
            id: undismissed_activity_notification.id,
            label: undismissed_activity_notification.label,
            language: program.language_code,
            message: undismissed_activity_notification.message,
            path: undismissed_activity_notification.path
          )
        )

        expect(result[:notifications][:viewed]).to contain_exactly(
          hash_including(
            class_cancelled: false,
            id: dismissed_activity_notification.id,
            label: dismissed_activity_notification.label,
            language: program.language_code,
            message: dismissed_activity_notification.message,
            path: dismissed_activity_notification.path
          )
        )
      end
    end
  end
end
