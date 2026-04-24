require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'
require 'capybara/rspec'

describe OneRoster::Instructor::CoursesController do
  let(:program) { create(:program_with_lessons) }
  let(:instructor) { create(:instructor) }
  let(:school_salesforce_id) { SecureRandom.uuid }
  let(:school) { create(:school, salesforce_id: school_salesforce_id) }
  let(:first_class_external_id) { SecureRandom.uuid }
  let(:first_class_name) { 'class title A' }
  let(:second_class_external_id) { SecureRandom.uuid }
  let(:second_class_name) { 'class title B' }
  let(:course_external_id) { SecureRandom.uuid }
  let(:course_name) { 'Course title 1' }
  let(:expected_course) do
    {
      'sourced_id' => course_external_id,
      'title' => course_name,
      'classes' => [
                     {
                       'sourced_id' => first_class_external_id,
                       'title' => first_class_name,
                       'school_salesforce_id' => school.salesforce_id,
                       'academic_sessions' => []
                     },
                     {
                       'sourced_id' => second_class_external_id,
                       'title' => second_class_name,
                       'school_salesforce_id' => school.salesforce_id,
                       'academic_sessions' => []
                     }
                   ]
    }
  end

  def do_request
    get target_path
  end

  before do
    school.instructors << instructor
    create(:one_roster_linked_user, user: instructor, school: school)
  end

  describe 'GET /add' do
    let(:target_path) do
      add_one_roster_instructor_courses_path(program)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'displays links to the index of Roster Assistant courses' do
        expected_courses_path = "/one_roster/#{program.id}/instructor/courses"
        do_request
        result = Capybara.string(response.body)
        link = result.find('a.add-course-link')
        expect(link.text.strip).to eq('ADD COURSE')
        expect(link['href']).to eq(expected_courses_path)
      end
    end
  end

  describe 'GET /index' do
    let(:target_path) do
      one_roster_instructor_courses_path(program)
    end
    let(:roster_assistant_client) do
      instance_double(OneRoster::Client, courses_for_school: [expected_course],
                                         last_request_successful?: true)
    end

    before do
      allow(OneRoster::Client).to receive(:new).and_return(roster_assistant_client)
      allow(roster_assistant_client).to receive(:school_inactive?).and_return(false)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'lists the Roster Assistant courses when the Roster Assistant request was successful' do
        do_request
        result = Capybara.string(response.body)
        expect(result).to have_selector('tbody') do |tbody|
          tds = tbody.find_css('td')
          expect(tds[0].text.strip).to eq course_name
          expect(tds[1].text.strip).to eq first_class_name
          expect(tds[2].text.strip).to eq school.name
          expect(tds[5].text.strip).to eq course_name
          expect(tds[6].text.strip).to eq second_class_name
          expect(tds[7].text.strip).to eq school.name
        end
      end

      it 'displays an error if the Roster Assistant request failed' do
        error_message = 'Sorry, but we are unable to retrieve your courses ' \
                        'from Roster Assistant at this time. Please try again later.'
        allow(roster_assistant_client).to receive(:courses_for_school).and_return(nil)
        allow(roster_assistant_client).to receive(:last_request_successful?).and_return(false)
        allow(roster_assistant_client).to receive(:school_inactive?).and_return(false)
        do_request
        expect(flash[:error]).to eq error_message
      end

      it 'does not display an error if the Roster Assistant request was successful' do
        allow(roster_assistant_client).to receive(:courses_for_school).and_return([])
        allow(roster_assistant_client).to receive(:last_request_successful?).and_return(true)
        do_request
        expect(flash[:error]).to be_nil
      end

      context 'when the salesforce id is not present in one of the classes' do
        let(:class_without_salesforce_id) do
          {
            'sourced_id' => SecureRandom.uuid,
            'title' => 'Test Class',
            'school_salesforce_id' => '',
            'academic_sessions' => []
          }
        end
        let(:user_info) do
          {
            guid: instructor.guid,
            first_name: instructor.first_name,
            last_name: instructor.last_name
          }
        end
        let(:payload) do
          {
            payload: [
              school_name: instructor.one_roster_linked_user.school.name,
              class_id: class_without_salesforce_id['sourced_id'],
              course_id: expected_course['sourced_id'],
              course_name: expected_course['title'],
              instructor: user_info
            ]
          }
        end

        before do
          expected_course['classes'] << class_without_salesforce_id
          create(:one_roster_linked_user, school: school, user: instructor)
          allow(STATS_PROXY).to receive(:info)
        end

        it 'logs a warning' do
          do_request
          expect(STATS_PROXY).to have_received(:info).with(hash_including(payload))
        end
      end
    end
  end

  describe 'POST /create' do
    def do_request
      post target_path
    end

    let(:section_params) { {} }
    let(:target_path) do
      one_roster_instructor_courses_path(program, section_params)
    end
    let(:roster_assistant_client) { instance_double(OneRoster::Client, courses_for_school: [expected_course]) }
    let(:available_course_package_ids) { [99] }

    before do
      allow(OneRoster::Client).to receive(:new).and_return(roster_assistant_client)
      allow(roster_assistant_client).to receive(:school_inactive?).and_return(false)
      allow(CourseLicenseCreatorWorker).to receive(:perform_in)
      allow_any_instance_of(CourseOptions).to receive(:available_course_package_ids)
        .and_return(available_course_package_ids)
      allow(Ua::OneRosterEnrollments).to receive(:create)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user' do
      let(:section_start_date) { 2.days.ago.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT) }
      let(:section_end_date) { 2.days.from_now.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT) }
      let(:base_section_params) do
        {
          class_external_id: first_class_external_id,
          course_external_id: course_external_id,
          start_date: section_start_date,
          end_date: section_end_date,
          salesforce_id: school.salesforce_id
        }
      end
      let(:section_identifier) do
        "#{course_external_id}::#{first_class_external_id}"
      end

      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      context 'when section_identifier is present' do
        let(:section_params) do
          {
            sections: [
                        { section: base_section_params }
                      ],
            selected_sections: [section_identifier]
          }
        end

        it 'creates a course' do
          expect { do_request }.to change(Course, :count).by(1)
        end

        it 'creates a section' do
          expect { do_request }.to change(Section, :count).by(1)
        end

        it 'creates a section_instructor record' do
          expect { do_request }.to change(SectionInstructor, :count).by(1)
        end

        it 'creates a one_roster_linked_sections record' do
          expect { do_request }.to change(OneRoster::LinkedSection, :count).by(1)
        end

        it 'queues the course license creation' do
          expect(CourseLicenseCreatorWorker).to receive(:perform_in)
          do_request
        end

        it 'redirects to the instructor dashboard' do
          do_request
          expect(response).to redirect_to(instructor_dashboard_path(program))
        end

        it 'notifies UA to create the sections enrollments' do
          expected_ua_params = {
            section_guid: nil,
            external_class_id: first_class_external_id
          }
          do_request
          expect(Ua::OneRosterEnrollments).to have_received(:create).with(sections: [expected_ua_params])
        end

        it 'displays a confirmation message' do
          do_request
          expect(flash[:notice]).to eq "Section '#{first_class_name}' has been created."
        end
      end

      shared_examples 'does not create records' do
        it 'does not create a course' do
          expect { do_request }.not_to change(Course, :count)
        end

        it 'does not create a section' do
          expect { do_request }.not_to change(Section, :count)
        end

        it 'does not create a section_instructor record' do
          expect { do_request }.not_to change(SectionInstructor, :count)
        end

        it 'does not create a one_roster_linked_sections record' do
          expect { do_request }.not_to change(OneRoster::LinkedSection, :count)
        end

        it 'redirects to the roster assistant courses index' do
          do_request
          expect(response).to redirect_to(one_roster_instructor_courses_path(program))
        end

        it 'does not notify UA to create the sections enrollments' do
          do_request
          expect(Ua::OneRosterEnrollments).not_to have_received(:create)
        end
      end

      context 'when section_identifier is absent' do
        let(:section_params) do
          {
            sections: [
                        { section: base_section_params }
                      ]
          }
        end

        include_examples 'does not create records'

        it 'displays a message informing that no section was selected' do
          do_request
          expect(flash[:error]).to eq "Please select a section."
        end
      end

      context 'when both date params are absent' do
        let(:section_params) do
          {
            sections: [
              { section: base_section_params.except(:start_date, :end_date) }
                      ],
            selected_sections: [section_identifier]
          }
        end

        include_examples 'does not create records'
      end

      context 'when start date param is absent' do
        let(:section_params) do
          {
            sections: [
              { section: base_section_params.except(:start_date) }
                      ],
            selected_sections: [section_identifier]
          }
        end

        include_examples 'does not create records'
      end

      context 'when end date param is absent' do
        let(:section_params) do
          {
            sections: [
              { section: base_section_params.except(:end_date) }
                      ],
            selected_sections: [section_identifier]
          }
        end

        include_examples 'does not create records'
      end
    end
  end

  describe 'DELETE /destroy' do
    def do_request
      delete target_path
    end

    let(:target_path) do
      one_roster_instructor_course_path(program, course)
    end
    let(:section) do
      section = create(:section_with_course)
      create(:one_roster_linked_section, section: section)
      section
    end
    let(:course) { section.course }

    include_examples 'require instructor with program access'

    context 'with a valid user' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      context 'with no errors' do
        it 'archives the section' do
          expect(section).not_to be_archived
          do_request
          section.reload
          expect(section).to be_archived
        end

        it 'archives the course' do
          expect(course).not_to be_archived
          do_request
          course.reload
          expect(course).to be_archived
        end

        it 'redirects to the instructor dashboard' do
          do_request
          expect(response).to redirect_to(instructor_dashboard_path(program))
        end

        it 'displays a confirmation message' do
          do_request
          expect(flash[:notice]).to eq "Course <b>#{course.name}</b> and its " \
                                       'sections were deleted successfully.'
        end
      end

      context 'with errors' do
        before do
          allow(Course).to receive(:find).and_return(course)
          allow(course).to receive(:sections).and_return([section])
        end

        it 'displays section errors' do
          section_error = 'Something went wrong with the section'
          error_obj = ActiveModel::Errors.new(section)
          allow(section).to receive(:archive) do
            error_obj.add(:base, section_error)
          end
          allow(section).to receive(:errors).and_return(error_obj)
          do_request
          expect(flash[:error]).to eq section_error
          course.reload
          expect(course).not_to be_archived
        end

        it 'displays course errors' do
          course_error = 'Something went wrong with the course'
          error_obj = OpenStruct.new(full_messages: [course_error])
          allow(course).to receive(:errors).and_return(error_obj)
          do_request
          expect(flash[:error]).to eq course_error
        end

        it 'redirects to the instructor dashboard' do
          do_request
          expect(response).to redirect_to(instructor_dashboard_path(program))
        end

        it 'does not remove the section, course or one_roster_linked_section records if enrollments archival fails' do
          bad_enrollment = build(:enrollment)
          expected_error = 'Enrollment archival failed'
          allow(bad_enrollment).to receive(:archive).and_raise(expected_error)
          allow(section).to receive(:enrollments).and_return(bad_enrollment)
          expect{ do_request }.to raise_error expected_error
          section.reload
          expect(section).not_to be_archived
          expect(section.course).not_to be_archived
          expect(section.one_roster_linked_section).not_to be_nil
        end
      end
    end
  end
end
