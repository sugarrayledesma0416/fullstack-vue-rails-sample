require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Jr::LessonsController do
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:unit) { create(:unit, program: program) }
  let!(:lesson) { create(:lesson, label: 'L1', name: 'Lesson <b>1<b>', unit: unit) }

  before do
    create(:active_enrollment, section: section, user: student)
  end

  describe 'GET /index' do
    let(:target_path) do
      jr_section_program_lessons_path(program_id: program.id, section_id: section.id)
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the index view of lessons in the program' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:index)

        expect(assigns(:page_title)).to eq('Activities')
        expect(assigns(:menu_location)).to eq('content')
      end
    end
  end

  describe 'GET /show' do
    let(:target_path) do
      jr_section_program_lesson_path(
        id: lesson.id, program_id: program.id, section_id: section.id
      )
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the show view for the specified lesson' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:show)

        expect(assigns(:menu_location)).to eq('content')
        expect(assigns(:lesson)).to eq(lesson)
        # Verifying that html tags got stripped out.
        expect(assigns(:page_title)).to eq('Lesson 1')
      end
    end
  end
end
