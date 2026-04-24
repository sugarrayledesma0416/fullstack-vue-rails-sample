require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Jr::GrownupsController do
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  before do
    create(:active_enrollment, section: section, user: student)
  end

  describe 'GET /show' do
    let(:target_path) do
      jr_section_grownups_path(section_id: section.id)
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the Grown-ups dashboard' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:show)

        expect(assigns(:page_title)).to eq('Welcome to the School-Home Connection')
        expect(assigns(:menu_location)).to eq('grownups')
        expect(assigns(:sub_location)).to eq('home')

        expect(session[:activity_return]).to eq(
          'label' => 'Return to Grown-ups Home',
          'url' => jr_section_grownups_path(section_id: section.id)
        )
      end
    end
  end
end
