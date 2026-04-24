describe OneRoster::CoursesPresenter do
  let(:instructor) { create(:instructor) }
  let(:program) { build_stubbed(:program) }
  let(:school_salesforce_id) { SecureRandom.uuid }
  let(:school) { create(:school, salesforce_id: school_salesforce_id) }
  let(:section) { create(:section, instructor: instructor) }
  let(:class_external_id) { SecureRandom.uuid }
  let(:course_external_id) { SecureRandom.uuid }
  let(:section_identifier) { "#{course_external_id}::#{class_external_id}" }
  let(:presenter) do
    described_class.new(instructor)
  end
  let(:start_date) { 1.day.ago }
  let(:end_date) { 10.days.from_now }
  let(:academic_sessions) do
    [
      {
        'start_date' => start_date.strftime('%Y-%m-%d'),
        'end_date' => end_date.strftime('%Y-%m-%d'),
        'school_year' => Time.now.strftime('%Y')
      }
    ]
  end

  context 'with a section with linked section' do
    let(:expected_courses) { ['list_of_courses'] }
    let(:one_roster_client) { instance_double(OneRoster::Client, courses_for_school: expected_courses,
                                                                 last_request_successful?: true) }

    before do
      create(:one_roster_linked_section, section: section,
                                         class_external_id: class_external_id,
                                         course_external_id: course_external_id)
      create(:one_roster_linked_user, user: instructor, school: school)
    end

    describe '#roster_assistant_sections_group_by_status' do
      let(:expected_course) do
        {
          'sourced_id' => 1,
          'title' => 'Course title 1',
          'classes' => [
            { 'sourced_id' => 'a', 'title' => 'class title A', 'school_salesforce_id' => school_salesforce_id },
            { 'sourced_id' => 'b', 'title' => 'class title B', 'school_salesforce_id' => school_salesforce_id }
          ]
        }
      end
      let(:expected_courses) { [expected_course] }
      let(:section_one_data) do
        {
          'course_sourced_id' => expected_course['sourced_id'],
          'course_title' => expected_course['title'],
          'end_date' => nil,
          'm3_section' => nil,
          'school' => school,
          'school_salesforce_id' => school_salesforce_id,
          'section_identifier' => OneRoster::LinkedSection.build_identifier(expected_course['sourced_id'],
                                                                            expected_course['classes'][0]['sourced_id']),
          'sourced_id' => expected_course['classes'][0]['sourced_id'],
          'start_date' => nil,
          'title' => expected_course['classes'][0]['title']
        }
      end
      let(:section_two_data) do
        {
          'course_sourced_id' => expected_course['sourced_id'],
          'course_title' => expected_course['title'],
          'end_date' => nil,
          'm3_section' => nil,
          'school' => school,
          'school_salesforce_id' => school_salesforce_id,
          'section_identifier' => OneRoster::LinkedSection.build_identifier(expected_course['sourced_id'],
                                                                            expected_course['classes'][1]['sourced_id']),
          'sourced_id' => expected_course['classes'][1]['sourced_id'],
          'start_date' => nil,
          'title' => expected_course['classes'][1]['title']
        }
      end
      before do
        allow(OneRoster::Client).to receive(:new).with(instructor.one_roster_linked_user.external_username)
                                                 .and_return(one_roster_client)
      end

      it 'returns an empty hash if the request to roster assistant failed' do
        allow(one_roster_client).to receive(:last_request_successful?).and_return(false)
        results = presenter.roster_assistant_sections_group_by_status
        expect(results).to eq({})
      end

      it 'returns the sections data grouped by ones not yet created and ones created' do
        section_two = create(:section, name: section_two_data['title'], instructor: instructor)
        create(:one_roster_linked_section, section: section_two,
                                           class_external_id: section_two_data['sourced_id'],
                                           course_external_id: section_two_data['course_sourced_id'])
        section_two_data['m3_section'] = section_two
        section_two_data['end_date'] = section_two.course.end_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
        section_two_data['start_date'] = section_two.course.start_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
        expected_response = {
          'available_sections' => [
            section_one_data
          ],
          'created_sections' => [
            section_two_data
          ]
        }
        expect(presenter.roster_assistant_sections_group_by_status).to eq(expected_response)
      end

      it 'populates the start_date and end_date for non created section if they have academic_sessions' do
        section_one_data['academic_sessions'] = expected_course['classes'][0]['academic_sessions'] = academic_sessions
        section_two_data['academic_sessions'] = expected_course['classes'][1]['academic_sessions'] = academic_sessions
        section_one_data['start_date'] = section_two_data['start_date'] = start_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
        section_one_data['end_date'] = section_two_data['end_date'] = end_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
        expected_response = {
          'available_sections' => [
            section_one_data,
            section_two_data
          ],
          'created_sections' => []
        }
        expect(presenter.roster_assistant_sections_group_by_status).to eq(expected_response)
      end

      it 'returns the school key as nil if the class data school_sales_force_id does not match a school' do
        section_one_data['school_salesforce_id'] = expected_course['classes'][0]['school_salesforce_id'] = 'non_existing_school_sales_force_id'
        section_one_data['school'] = nil
        expected_response = {
          'available_sections' => [
            section_one_data,
            section_two_data
          ],
          'created_sections' => []
        }
        expect(presenter.roster_assistant_sections_group_by_status).to eq(expected_response)
      end
    end
  end
end
