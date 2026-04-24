require 'requests/login_helper_methods'

# Without this require, in some tests runs, depending on load order, the
# Instructor::DashboardController ends up receiving the requests
# instead of InstitutionAdmin::DashboardController.
require 'institution_admin/dashboard_controller'

describe InstitutionAdmin::DashboardController do
  let(:user) { create(:user) }
  let(:institution_admin) { create(:institution_admin) }
  let(:district) { create(:district, name: 'VHL District 1') }
  let(:school_one) { create(:school) }
  let(:school_two) { create(:school, parent_institution_id: school_one.id) }
  let(:program) { create(:program_with_toc_entries) }
  let(:instructor) { create(:instructor) }
  let(:content_object) do
    instance_double(
      MaestroActivityEngine::ActivityContent::CompositionContent,
      activity_type: 'composition',
      content_summary: { question_1: 1 },
      grading_method: 'instructor_graded',
      max_attempts: 2,
      points_possible: 10,
      submittable?: true,
      randomizable?: true
    )
  end
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }
  let(:institution_admin_created_activity) { create(:instructor_created_activity,
                                                    lesson: lesson,
                                                    toc_location: strand.location,
                                                    instructor: institution_admin,
                                                    title: 'Title example') }

  before do
    stub_request(:get, /programs_cover_image_urls/).to_return(
      status: 200,
      body: {}.to_json
    )
    create(
      :school_program_admin_user,
      account_type: institution_admin.account_type,
      program: program,
      school: school_one,
      user: institution_admin
    )
    district.schools << school_one
    create(
      :school_user,
      user: institution_admin,
      school: school_one
    )
  end

  describe 'GET :index' do
    def do_request
      get(institution_admin_dashboard_path)
    end

    it 'allows access to an institution admin' do
      log_in_user(institution_admin)

      do_request

      expect(response).to be_ok
      expect(response).to render_template(:index)
    end

    it 'does not allow access to a normal user' do
      log_in_user(user)

      do_request

      expect(response).to be_unauthorized
    end
  end

  describe 'GET :courses' do
    it 'displays the courses page' do
      allow(Maestro::User).to receive(:accessible_programs)
        .with(institution_admin.guid)
        .and_return([program])
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program)
        .and_return([])
      allow(Maestro::School).to receive(:instructors)
        .with(school_one.guid, program.id)
        .and_return('instructor_ids' => [instructor.id])

      log_in_user(institution_admin)

      get(institution_admin_courses_current_path(program_id: program.id, school_id: school_one.id))

      expect(response).to render_template(:courses)
    end
  end

  context 'with a valid institution admin' do
    before do
      allow(Maestro::User).to receive(:accessible_programs).with(institution_admin.guid)
                                                           .and_return([program])
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([])
      allow(Maestro::School).to receive(:instructors)
        .with(school_one.guid, program.id)
        .and_return('instructor_ids' => [instructor.id])
      log_in_user(institution_admin)
    end

    describe 'POST #create_sections' do
      context 'validation failures' do
        it 'fails to creates a section when there is an instructor with an empty role' do
          course = create(:course, owner: institution_admin, is_enterprise: true, school_id: school_one.id)
          section = create(:section, course: course, is_enterprise: true)

          payload = {
            school_id: school_one.id,
            course_id: course.id,
            section: {
              open_to_students: true,
              course_id: course.id,
              name: 'test',
              hide_owner_name: true,
              additional_instructors: [
                {
                  instructor_id: instructor.id,
                  role: '',
                  show: true
                }
              ]
            }
          }

          post(institution_admin_create_section_path, params: payload)
          json = JSON.parse response.body
          expect(json["error"]).to eq("Additional instructors must have a role")
        end

        it 'fails to creates a section when there is an instructor with an empty role' do
          course = create(:course, owner: institution_admin, is_enterprise: true, school_id: school_one.id)
          section = create(:section, course: course, is_enterprise: true)

          payload = {
            school_id: school_one.id,
            course_id: course.id,
            section: {
              open_to_students: true,
              course_id: course.id,
              name: 'test',
              hide_owner_name: true,
              additional_instructors: [
                {
                  instructor_id: instructor.id,
                  role: '',
                  show: true
                }
              ]
            }
          }

          post(institution_admin_create_section_path, params: payload)
          json = JSON.parse response.body
          expect(json["error"]).to eq("Additional instructors must have a role")
        end

        it 'fails to creates a section when no school id is passed in' do
          course = create(:course, owner: institution_admin)

          payload = {
            course_id: course.id,
            section: {
              open_to_students: true,
              course_id: course.id,
              name: 'test',
              hide_owner_name: true,
              additional_instructors: [
                {
                  instructor_id: instructor.id,
                  role: 'Co-instructor',
                  show: true
                }
              ]
            }
          }

          post(institution_admin_create_section_path, params: payload)
          json = JSON.parse response.body
          expect(json["error"]).to eq("School not found")
        end

        it 'fails to creates a section when no course id is passed in' do
          course = create(:course, owner: institution_admin)

          payload = {
            school_id: school_one.id,
            section: {
              open_to_students: true,
              course_id: course.id,
              name: 'test',
              hide_owner_name: true,
              additional_instructors: [
                {
                  instructor_id: instructor.id,
                  role: 'Co-instructor',
                  show: true
                }
              ]
            }
          }

          post(institution_admin_create_section_path, params: payload)
          json = JSON.parse response.body
          expect(json["error"]).to eq("Course not found")
        end

        it 'fails to creates a section when the enterprise course has no enterprise section created' do
          course = create(:course, owner: institution_admin, is_enterprise: true, school_id: school_one.id)

          payload = {
            school_id: school_one.id,
            course_id: course.id,
            section: {
              open_to_students: true,
              course_id: course.id,
              name: 'test',
              hide_owner_name: true,
              additional_instructors: [
                {
                  instructor_id: instructor.id,
                  role: 'Co-instructor',
                  show: true
                }
              ]
            }
          }

          expect{post(institution_admin_create_section_path, params: payload)}.to raise_error(ArgumentError)
        end
      end

      context 'section successfully created' do
        it 'creates a section when all data is correct' do
          course = create(:course, owner: institution_admin, is_enterprise: true, school_id: school_one.id)
          section = create(:section, course: course, is_enterprise: true)

          payload = {
            school_id: school_one.id,
            course_id: course.id,
            section: {
              open_to_students: true,
              course_id: course.id,
              name: 'test',
              hide_owner_name: true,
              additional_instructors: [
                {
                  instructor_id: instructor.id,
                  role: 'Co-instructor',
                  show: true
                }
              ]
            }
          }

          post(institution_admin_create_section_path, params: payload)
          json = JSON.parse response.body
          expect(json["status"]).to eq("ok")
        end
      end
    end

    describe 'GET #courses' do
      it 'displays the courses page' do
        get(institution_admin_courses_current_path(program_id: program.id, school_id: school_one.id))
        expect(response).to render_template(:courses)
      end
    end

    describe 'GET #section_metrics' do
      it 'displays the section metrics page' do
        get(institution_admin_section_metrics_path(program.id, school_id: school_one.id))
        expect(response).to render_template(:section_metrics)
      end
    end

    describe 'POST #hide_course_from_instructor_dash' do
      it 'sets the hide_from_instructor_dashboard flag to true' do
        course = create(:course, owner: institution_admin)
        section = create(:section, course: course, instructor: institution_admin)

        post(institution_admin_hide_course_from_instructor_dash_path(course.id))
        instructor_record = SectionInstructor.where(section: section,
                                                    user_id: institution_admin.id,
                                                    role: 'Instructor')
                                             .first

        expect(instructor_record.hide_from_instructor_dashboard).to be(true)
      end
    end

    describe 'POST #show_course_on_instructor_dash' do
      let(:course) { create(:course) }

      it 'sets the hide_from_instructor_dashboard flag to false' do
        course = create(:course, owner: institution_admin)
        section = create(:section, course: course, instructor: institution_admin)

        post(institution_admin_show_course_on_instructor_dash_path(course.id))
        instructor_record = SectionInstructor.where(section: section,
                                                    user_id: institution_admin.id,
                                                    role: 'Instructor')
                                             .first

        expect(instructor_record.hide_from_instructor_dashboard).to be(false)
      end
    end

    describe 'POST #delete_course' do
      let(:school) { school_one }
      let(:course) do
        create(
          :enterprise_course,
          owner: institution_admin,
          school:,
          enterprise_section: create(:enterprise_section, instructor: institution_admin)
        )
      end
      let(:redirect_path) do
        institution_admin_courses_current_path(program_id: course.program_id, school_id: course.school_id)
      end

      def do_request
        post institution_admin_delete_course_path(course_id: course.id, school_id: school_one.id)
      end

      before { log_in_user(institution_admin) }

      context 'when the course does not have sections' do
        let(:flash_message) { "Course <b>#{course.name}</b> was deleted successfully." }

        before { do_request }

        it { expect(course.enterprise_section.reload.is_archived).to be true }
        it { expect(course.reload.is_archived).to be true }
        it { expect(response).to redirect_to(redirect_path) }
        it { expect(flash[:notice]).to eq(flash_message) }
      end

      context 'when the course have sections' do
        let(:flash_message) do
          "You cannot delete <b>#{course.name}</b> because it has sections created."
        end

        before do
          create(:section, course:)
          do_request
        end

        it { expect(course.enterprise_section.reload.is_archived).to be false }
        it { expect(course.reload.is_archived).to be false }
        it { expect(response).to redirect_to(redirect_path) }
        it { expect(flash[:error]).to eq(flash_message) }
      end

      context 'when the course does not belong to the requested school user' do
        let(:school) { create(:school) }

        it { expect { do_request }.to raise_error(ActiveRecord::RecordNotFound) }
      end
    end

    describe 'POST #create_sections' do
      let(:school) { school_one }
      let(:course) do
        create(
          :enterprise_course,
          owner: institution_admin,
          school:,
          enterprise_section: create(:enterprise_section, instructor: institution_admin)
        )
      end
      let(:section_params) do
        {
          hide_owner_name: false,
          name: 'real section test',
          days_to_show_assignment_due_date: 3,
          due_time: '11:00PM',
          time_zone: 'Pacific Time (US & Canada)',
          additional_instructors: additional_instructors_params
        }
      end
      let(:additional_instructors_params) do
        [
          {
            instructor_id: instructor.id,
            role: 'Co-instructor',
            show: true
          }
        ]
      end
      let(:request_params) { { section: section_params } }

      def do_request
        post(
          institution_admin_create_section_path(course_id: course.id, school_id: school_one.id),
          params: JSON.dump(request_params),
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )
      end

      before { log_in_user(institution_admin) }

      context 'when successful' do
        it 'returns successful status' do
          do_request

          expect(response).to have_http_status(:ok)
        end

        it { expect { do_request }.to change(Section, :count).by(1) }
        it { expect { do_request }.to change(SectionInstructor, :count).by(2) }
      end

      context 'when the school does not exist' do
        before do
          allow(school_one).to receive(:id).and_return(0)
          do_request
        end

        it { expect(response).to have_http_status(:not_found) }
      end

      context 'when the course does not belong to the requested school user' do
        let(:school) { create(:school) }

        before { do_request }

        it { expect(response).to have_http_status(:not_found) }
      end
    end

    describe 'POST # update_section' do
      let(:course) do
        create(
          :enterprise_course,
          owner: institution_admin,
          school: school_one,
          enterprise_section: create(:enterprise_section, instructor: institution_admin)
        )
      end
      let(:section) do
        create(
          :section,
          instructor: institution_admin,
          course:
        )
      end
      let(:section_params) do
        {
          section_id: section.id,
          hide_owner_name: false,
          name: 'real section test',
          days_to_show_assignment_due_date: 3,
          due_time: '11:00PM',
          time_zone: 'Pacific Time (US & Canada)',
          additional_instructors: additional_instructors_params
        }
      end
      let(:additional_instructors_params) do
        [
          {
            instructor_id: instructor.id,
            role: 'Co-instructor',
            show: true
          }
        ]
      end
      let(:section_params_failed) do
        {
          section_id: section.id,
          hide_owner_name: false,
          name: 'real section test',
          days_to_show_assignment_due_date: 3,
          due_time: '11:00PM',
          time_zone: 'Pacific Time (US & Canada)',
          additional_instructors: additional_instructors_params_failed
        }
      end
      let(:additional_instructors_params_failed) do
        [
          {
            instructor_id: instructor.id,
            role: '',
            show: true
          }
        ]
      end
      let(:request_params) { { section: section_params } }
      let(:request_params_failed) { { section: section_params_failed } }

      def do_request
        post(
          institution_admin_update_section_path(course_id: course.id, school_id: school_one.id),
          params: JSON.dump(request_params),
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )
      end

      def do_request_failed
        post(
          institution_admin_update_section_path(course_id: course.id, school_id: school_one.id),
          params: JSON.dump(request_params_failed),
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )
      end

      before do
        log_in_user(institution_admin)
        section.reload
      end

      context 'when successful' do
        it 'returns successful status' do
          do_request

          expect(response).to have_http_status(:ok)
        end

        it { expect { do_request }.to change(SectionInstructor, :count).by(1) }
      end

      context 'when no additional instructor ' do
        it 'returns error' do
          do_request_failed

          json = JSON.parse response.body
          expect(json["error"]).to eq("Additional instructors must have a role")
        end

        it { expect { do_request_failed }.to change(SectionInstructor, :count).by(0) }
      end

      context 'when the section does not exist' do
        before do
          allow(section).to receive(:id).and_return(0)
          do_request
        end

        it { expect(response).to have_http_status(:not_found) }
      end

      context 'when the course is not enterprise' do
        let(:course) do
          create(
            :course,
            owner: institution_admin,
            school: school_one
          )
        end

        before do
          do_request
        end

        it { expect(response).to have_http_status(:unprocessable_entity) }
      end

      context 'when invalid parameters' do
        before do
          section_params[:name] = ''
          allow(VHLMonitor).to receive(:error)
          do_request
        end

        it { expect(response).to have_http_status(:unprocessable_entity) }
        it { expect(VHLMonitor).to have_received(:error) }
      end
    end

    describe 'POST #delete_section' do
      let(:course) do
        create(
          :enterprise_course,
          owner: institution_admin,
          school: school_one,
          enterprise_section: create(:enterprise_section, instructor: institution_admin)
        )
      end
      let(:section) do
        create(
          :section,
          instructor: institution_admin,
          course:
        )
      end
      let(:redirect_path) do
        institution_admin_sections_path(
          course_id: course.id,
          program_id: course.program_id,
          school_id: course.school_id
        )
      end

      def do_request
        post institution_admin_delete_section_path(section: { id: section.id }, school_id: school_one.id)
      end

      before { log_in_user(institution_admin) }

      context 'when successful' do
        let(:flash_message) { "Section <b>#{section.name}</b> was deleted successfully." }

        before { do_request }

        it { expect(section.reload.is_archived).to be true }
        it { expect(response).to redirect_to(redirect_path) }
        it { expect(flash[:notice]).to eq(flash_message) }
      end

      context 'when the section does not exist' do
        before do
          allow(section).to receive(:id).and_return(0)
        end

        it { expect { do_request }.to raise_error(ActiveRecord::RecordNotFound) }
      end

      context 'when the course is not enterprise' do
        let(:course) do
          create(
            :course,
            owner: institution_admin,
            school: school_one
          )
        end
        let(:flash_message) { "Section <b>#{section.name}</b> does not belongs to an enterprise course." }

        before { do_request }

        it { expect(section.reload.is_archived).to be false }
        it { expect(response).to redirect_to(redirect_path) }
        it { expect(flash[:error]).to eq(flash_message) }
      end
    end
  end
end
