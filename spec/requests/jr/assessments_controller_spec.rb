require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Jr::AssessmentsController do
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
      jr_section_assessments_path(section_id: section.id)
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the Assesssments index' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:index)

        expect(assigns(:page_title)).to eq('Assessments')
        expect(assigns(:menu_location)).to eq('content')

        expect(session[:activity_return]).to eq(
          'label' => 'Return to Assessments',
          'url' => jr_section_assessments_path(section_id: section.id)
        )
      end
    end
  end
end
