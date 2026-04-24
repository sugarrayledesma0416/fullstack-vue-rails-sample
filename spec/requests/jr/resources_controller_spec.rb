require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Jr::ResourcesController do
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  before do
    create(:active_enrollment, section: section, user: student)
  end

  describe 'GET /index' do
    let(:target_path) do
      jr_resources_path(program_id: program.id, section_id: section.id)
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the Grownups dashboard' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:index)

        expect(assigns(:page_header)).to eq('Resources')
        expect(assigns(:menu_location)).to eq('grownups')
        expect(assigns(:sub_location)).to eq('resources')
        expect(assigns(:no_section_navigation)).to be_truthy

        expect(assigns(:presenter)).to be_a(ResourcesPresenter)
      end
    end
  end
end
