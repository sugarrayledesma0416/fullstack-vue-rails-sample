require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Lti::ResourceLinksController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:link_id) { SecureRandom.uuid }
  let(:activity) { create(:activity) }
  let(:access_updater) { instance_double(ActiveEnrollmentAccessUpdater, update: nil) }

  describe 'GET /show' do
    def target_path(optional_params)
      lti_resource_link_path(
        {
          activity_id: activity.id,
          id: link_id,
          program_id: program.id
        }.merge(optional_params)
      )
    end

    def do_request(optional_params = {})
      get target_path(optional_params)
    end

    before do
      allow(ActiveEnrollmentAccessUpdater).to receive(:new).and_return(access_updater)
    end

    include_examples 'require logged in user'

    context 'with a valid logged-in student,' do
      before do
        create(:enrollment, section: section, user: student)
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'redirects to the student activity show page' do
        do_request

        expect(response).to redirect_to(
          section_activity_path(
            id: activity.id,
            section_id: section.id
          )
        )
      end

      it 'instantiates an ActiveEnrollmentAccessUpdater if the student is' \
         'accessing with a section_guid param' do
        do_request({ section_guid: section.guid })

        expect(access_updater).to have_received(:update)
      end

      it 'does not instantiates an ActiveEnrollmentAccessUpdater if the student ' \
         'is accessing without a section_guid' do
        do_request

        expect(ActiveEnrollmentAccessUpdater).not_to have_received(:new)
      end
    end

    context 'with a valid logged-in instructor,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'redirects to the instructor toc' do
        do_request

        expect(response).to redirect_to(
          section_activity_path(
            id: activity.id,
            section_id: 0
          )
        )
      end

      it 'does not instantiates an ActiveEnrollmentAccessUpdater' do
        do_request({ section_guid: section.guid })

        expect(ActiveEnrollmentAccessUpdater).not_to have_received(:new)
      end
    end
  end
end
