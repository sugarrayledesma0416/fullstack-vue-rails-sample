require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Jr::SectionsController do
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
      jr_course_section_path(course_id: course.id, section_id: section.id)
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the student dashboard' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:show)

        expect(assigns(:section)).to eq(section)

        expect(assigns(:presenter)).to be_a(StudentDashboardPresenter)

        expect(assigns(:course)).to eq(course)

        expect(assigns(:instructor)).to eq(instructor)

        expect(session[:activity_return]).to eq(
          'label' => 'Return to Dashboard',
          'url' => jr_course_section_path(
            course_id: course.id,
            section_id: section.id
          )
        )
      end
    end
  end

  describe 'GET /study_schedule' do
    let(:target_path) do
      jr_section_study_schedule_path(section_id: section.id)
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the student calendar' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:study_schedule)

        expect(assigns(:menu_location)).to eq('grownups')
        expect(assigns(:sub_location)).to eq('calendar')

        expect(assigns(:calendar_presenter)).to be_a(CalendarPresenter)

        expect(session[:activity_return]).to eq(
          'label' => 'Return to Calendar',
          'url' => jr_section_study_schedule_path(
            section_id: section.id
          )
        )
      end
    end
  end
end
