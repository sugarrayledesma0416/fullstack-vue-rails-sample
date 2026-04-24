require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Jr::ContentController do
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  describe 'GET /show' do
    let(:target_path) do
      jr_section_program_content_path(program_id: program.id, section_id: section.id)
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the Content home page with an unenrolled student' do
        get jr_section_program_content_path(program_id: program.id, section_id: 0)

        do_request

        expect(response).to be_ok

        expect(response).to render_template(:show)

        expect(assigns(:page_header)).to eq('Content')
        expect(assigns(:menu_location)).to eq('content')
      end

      it 'renders the Content home page with an enrolled student' do
        create(:active_enrollment, section: section, user: student)

        do_request

        expect(response).to be_ok

        expect(response).to render_template(:show)

        expect(assigns(:page_header)).to eq('Content')
        expect(assigns(:menu_location)).to eq('content')
      end
    end
  end
end
