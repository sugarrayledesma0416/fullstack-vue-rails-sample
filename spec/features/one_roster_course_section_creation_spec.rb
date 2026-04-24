feature 'One Roster course and section creation',
  chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:school_salesforce_id) { '123' }
  let(:district) { create(:district) }
  let(:school) do
    create(:one_roster_school, district: district, salesforce_id: school_salesforce_id)
  end
  let(:instructor) { create(:instructor) }
  let(:program) { create(:vol_program_with_toc_entries) }
  let(:ra_course) do
    {
      sourced_id: 1,
      title: 'Course title 1',
      classes: [
                 {
                   sourced_id: 'a',
                   title: 'class title A',
                   school_salesforce_id: school_salesforce_id,
                   academic_sessions: []
                 },
                 {
                   sourced_id: 'b',
                   title: 'class title B',
                   school_salesforce_id: school_salesforce_id,
                   academic_sessions: academic_sessions
                 },
                 {
                   sourced_id: 'c',
                   title: 'class title C',
                   school_salesforce_id: school_salesforce_id,
                   academic_sessions: []
                 }
               ]
    }
  end
  let(:expected_response) do
    { courses: [ra_course] }
  end
  let(:instructor_courses_endpoint) do
    "#{RA_URL}/one_roster_api/courses?school_salesforce_id=#{school_salesforce_id}&username=#{instructor.one_roster_linked_user.external_username}"
  end
  let(:section) { create(:section_with_course, instructor: instructor) }
  let(:academic_session_start_date) { 1.day.from_now }
  let(:academic_session_end_date) { 70.days.from_now }
  let(:academic_session_school_year) { Time.zone.now.strftime('%Y') }
  let(:academic_sessions) do
    [
      {
        start_date: academic_session_start_date.strftime('%Y-%m-%d'),
        end_date: academic_session_end_date.strftime('%Y-%m-%d'),
        school_year: academic_session_school_year
      }
    ]
  end

  before do
    instructor.schools << school
    create(:one_roster_linked_user, user: instructor, school: school)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    stub_request(:get, instructor_courses_endpoint).to_return(status: 200,
                                                              body: expected_response.to_json,
                                                              headers: { 'Content-Type' => 'application/json' })
  end

  def course_checkbox(identifier)
    find('.c-form-item__checkbox', id: "course_section__#{identifier}")
  end

  def course_datepicker(identifier, start_or_end_date)
    find('.c-form-item__input--datepicker', id: "#{start_or_end_date}__#{identifier}")
  end

  scenario 'As an instructor in the RosterAssistant courses index page,' \
    'I can see the data of an existing course greyed out' do
    step 'There are existing courses for the current program and RA data' do
      section.update!(name: ra_course[:classes][0][:title])
      create(:one_roster_linked_section, section: section,
                                         course_external_id: ra_course[:sourced_id],
                                         class_external_id: ra_course[:classes][0][:sourced_id])
      section.course.update(program: program)
    end

    log_in_as(instructor)
    visit one_roster_instructor_courses_path(program)

    purpose 'I see a row for the existing section' do
      expect(page).to have_selector('.js-enter')
      expect(page).to have_selector(".test-existing-section-row-#{section.id}")
      within(".test-existing-section-row-#{section.id}") do
        find('td:nth-child(2)', text: section.name)
        find('td:nth-child(3)', text: section.program.title.html_safe)
        find('td:nth-child(4)', text: section.school.name)
        find('td:nth-child(5)', text: section.course.start_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT))
        find('td:nth-child(6)', text: section.course.end_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT))
        find('td:nth-child(7)', text: section.instructor.last_name_first)
      end
    end
    purpose 'I see an enabled checkbox for the RA courses that have not been created in M3' do
      (1..2).each do |class_index|
        non_existing_course_identifier = OneRoster::LinkedSection.build_identifier(ra_course[:sourced_id],
                                                                                   ra_course[:classes][class_index][:sourced_id])
        expect(
          course_checkbox(non_existing_course_identifier)
        ).not_to be_disabled
      end
    end
    purpose 'I see populated the start and end date for the non created course that has an academic session' do
      course_identifier = OneRoster::LinkedSection.build_identifier(ra_course[:sourced_id],
                                                                    ra_course[:classes][1][:sourced_id])
      expect(course_datepicker(course_identifier, :start_date).value).to eq academic_session_start_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
      expect(course_datepicker(course_identifier, :start_date)).to be_readonly
      expect(course_datepicker(course_identifier, :end_date).value).to eq academic_session_end_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
      expect(course_datepicker(course_identifier, :end_date)).to be_readonly
    end
    purpose 'I see an editable start and end date for the non created course that does not have an academic session' do
      course_identifier = OneRoster::LinkedSection.build_identifier(ra_course[:sourced_id],
                                                                    ra_course[:classes][2][:sourced_id])
      expect(course_datepicker(course_identifier, :start_date).value).to eq ''
      expect(course_datepicker(course_identifier, :start_date)).not_to be_readonly
      expect(course_datepicker(course_identifier, :end_date).value).to eq ''
      expect(course_datepicker(course_identifier, :end_date)).not_to be_readonly
    end
    purpose 'I do not see the message shown when there are not courses to display' do
      expect(page).not_to have_selector('.test-no-courses-message')
    end
  end

  scenario 'As an instructor in the RosterAssistant courses index page,' \
    'I cannot see the data of an existing course of a different program' do
    other_program = create(:program)
    step 'There are existing courses for a different program and RA data' do
      create(:one_roster_linked_section, section: section,
                                         course_external_id: ra_course[:sourced_id],
                                         class_external_id: ra_course[:classes][0][:sourced_id])
      section.course.update(program: other_program)
    end

    log_in_as(instructor)
    visit one_roster_instructor_courses_path(program)

    purpose 'I do not see that the existing course row' do
      expect(page).to have_selector('.js-enter')
      expect(page).not_to have_selector('.c-form-item__checkbox', id: "course_section__#{section.one_roster_linked_section.identifier.keys[0]}")
    end
    purpose 'I see an enabled checkbox for the RA course that has not been created in M3' do
      non_existing_course_identifier = OneRoster::LinkedSection.build_identifier(ra_course[:sourced_id],
                                                                                 ra_course[:classes][1][:sourced_id])
      expect(
        course_checkbox(non_existing_course_identifier)
      ).not_to be_disabled
    end
    purpose 'I do not see the message shown when there are not courses to display' do
      expect(page).not_to have_selector('.test-no-courses-message')
    end
  end

  scenario 'As an instructor in the RosterAssistant courses index page,' \
    'I cannot hit the submit button if no course is selected' do
    log_in_as(instructor)
    visit one_roster_instructor_courses_path(program)

    purpose 'I see that the submit button is disabled by default' do
      expect(page).to have_selector('.js-enter[disabled]')
    end
    purpose 'I can click any of the courses checkbox' do
      step 'Click on the first checkbox' do
        first('.c-form-item__label').click
      end
    end
    purpose 'I see that the submit button is now enabled' do
      submit_button = find('.js-enter')
      expect(submit_button).not_to be_disabled
    end
    purpose 'I see a confirmation modal to create the courses' do
      expect(page).to have_selector('.js-confirmation-modal', visible: false)
      click_on('Confirm')
      confirmation_modal = find('.js-confirmation-modal', visible: true)
      within(confirmation_modal) do
        expect(page).to have_selector('p', text: "All selected courses will be added to #{program.title.html_safe}.")
        click_on('Cancel')
      end
      expect(page).to have_selector('.js-confirmation-modal', visible: false)
      click_on('Confirm')
      within(confirmation_modal) do
        click_on('Ok')
      end
    end
  end

  scenario 'As an instructor in the RosterAssistant courses index page,' \
    'if there are no courses, I see a message that lets me know that' do
    stub_request(:get, instructor_courses_endpoint).to_return(status: 200,
                                                              body: { courses: [] }.to_json,
                                                              headers: { 'Content-Type' => 'application/json' })
    log_in_as(instructor)
    visit one_roster_instructor_courses_path(program)

    purpose 'I see a message that tell me that there are no course to create' do
      expect(page).to have_selector('.test-no-courses-message', exact_text: 'There are no courses left to create.')
    end
    purpose 'I do not see a submit button' do
      expect(page).not_to have_selector('.js-enter')
    end
  end

  context 'when the salesforce_id in RA has not been set for the organization' do
    let(:school_salesforce_id) { '' }

    scenario 'As an instructor in the RosterAssistant courses index page,' \
      'I cannot create the courses' do
      log_in_as(instructor)
      visit one_roster_instructor_courses_path(program)

      purpose 'The checkboxs are disabled' do
        page.find_all('.c-form-item__checkbox').each do |element|
          expect(element).to be_disabled
        end
      end

      purpose 'The date fields are disabled' do
        page.find_all('.c-form-item__input--datepicker').each do |element|
          expect(element).to be_disabled
        end
      end

      purpose 'I do not see a submit button' do
        expect(page).not_to have_selector('.js-enter')
      end
    end
  end
end
