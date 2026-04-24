require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Jr::AnnouncementsController do
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  before do
    create(:active_enrollment, section: section, user: student)
  end

  describe 'GET /show' do
    let(:announcement) { create(:announcement) }

    let(:target_path) do
      jr_section_announcement_path(id: announcement.id, section_id: section.id)
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the announcement show view' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:show)

        expect(assigns(:page_title)).to eq('Announcement')
        expect(assigns(:menu_location)).to eq('grownups')

        expect(assigns(:announcement)).to eq(announcement)

        expect(assigns(:return_label)).to eq(
          'Return to Grown-ups Home'
        )

        expect(assigns(:return_url)).to eq(
          jr_section_grownups_path(section_id: section.id)
        )
      end
    end
  end
end
