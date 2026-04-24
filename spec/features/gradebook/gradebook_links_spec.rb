# encoding: utf-8

feature 'Gradebook links' do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:program) { create(:program_with_lessons) }
  let(:no_course_program) { create(:program) }
  let(:school) { create(:school) }
  let(:instructor) { create(:instructor, schools: [school]) }

  around do |example|
    old_analytics = Rails.configuration.enable_analytics
    Rails.configuration.enable_analytics = false
    example.run
    Rails.configuration.enable_analytics = old_analytics
  end

  scenario 'As an instructor with no courses, I see a no-courses message ' \
           'when following a link to the gradebook from my dashboard',
           chrome: true, js: true do
    initialize_program_access_client_calls_for_instructor(
      instructor, no_course_program
    )
    log_in_as(instructor)
    visit "/instructor/dashboard/#{no_course_program.id}"

    find('a.c-menu__title', text: 'Grade').click
    find('a.c-menu__item', text: 'Gradebook').click

    expect(page).to have_content("currently don't have a course")
  end

  scenario 'As an instructor with only closed courses, I see a ' \
           'no-assignments message when following a link to the gradebook ' \
           'from my dashboard', new_gb_sync: true, chrome: true, js: true do
    initialize_program_access_client_calls_for_instructor(
      instructor, program
    )
    closed_course = create(
      :closed_course, owner: instructor, program: program, school: school
    )
    create(:section, course: closed_course, instructor: instructor)
    log_in_as(instructor)

    visit "/instructor/dashboard/#{program.id}"

    find('a.c-menu__title', text: 'Grade').click
    find('a.c-menu__item', text: 'Gradebook').click

    expect(page).to have_content('There are no assignments.')
  end

  scenario 'As co-instructor who is not a course owner, I can follow a link to ' \
           'the gradebook from my dashboard', nondeterministic: true do
    non_owner = create(:instructor)
    open_course = create(:open_course, owner: instructor, program: program)
    section = create(:section, course: open_course)
    create(:section_instructor, user_id: non_owner.id, section_id: section.id)
    initialize_program_access_client_calls_for_instructor(non_owner, program)
    log_in_as(non_owner)
    visit "/instructor/dashboard/#{program.id}"

    expect(page).to have_link('Gradebook')
  end

  scenario 'As an instructor in a LTI Rostering school that visits a section,' \
           'I cannot add or remove students.' do
    lti_platform = create(:lti_rostering_platform)
    lti_rostering_instructor = create(
      :lti_rostering_instructor,
      schools: [lti_platform.school]
    )
    create(
      :lti_rostering_user_link,
      user: lti_rostering_instructor,
      lti_platform: lti_platform
    )
    open_course = create(
      :open_course,
      owner: lti_rostering_instructor,
      program: program,
      name: 'my_lti_course'
    )
    section = create(:section, course: open_course, instructor: lti_rostering_instructor)
    step 'I log in' do
      initialize_program_access_client_calls_for_instructor(lti_rostering_instructor, program)
      log_in_as(lti_rostering_instructor)
    end
    step 'I go to the section roster page' do
      visit section_roster_path(program, section, course_id: open_course.id)
    end
    step 'I cannot see a link to add or remove students' do
      expect(page).to have_no_selector('.js-add-students')
      expect(page).to have_no_selector('.js-drop-students')
    end
  end

  scenario 'As an instructor in a one_roster school that visits a section,' \
           'I cannot add or remove students, and I cannot see the students emails' do
    course_name = 'my_ra_course'
    one_roster_school = create(:one_roster_school)
    one_roster_instructor = create(
      :one_roster_instructor,
      schools: [one_roster_school]
    )
    student_roster = create(:one_roster_student, schools: [one_roster_school])

    create(:one_roster_linked_user, user: student_roster, school: one_roster_school)

    create(
      :one_roster_linked_user,
      user: one_roster_instructor,
      school: one_roster_school
    )
    open_course = create(:open_course, owner: one_roster_instructor, program: program, name: course_name)
    section = create(:section, course: open_course, instructor: one_roster_instructor)

    create(:enrollment,
           user: student_roster,
           section: section,
           sufficient_access: false)
    create(:attempt, user: student_roster, section: section)
    allow(Maestro::StudentGracePeriod).to receive(:all_for_course).and_return([])
    allow(Maestro::UserAccess).to receive(:immediate_access_revoke_list).and_return({})

    step 'I log in' do
      initialize_program_access_client_calls_for_instructor(one_roster_instructor, program)
      log_in_as(one_roster_instructor)
    end
    step 'I go to the section roster page' do
      visit section_roster_path(program, section, course_id: open_course.id)
    end
    step 'I cannot see a link to add or remove students' do
      expect(page).to have_no_selector('.js-add-students')
      expect(page).to have_no_selector('.js-drop-students')
    end
    step 'I see the students emails' do
      expect(page).to have_selector('th', text: 'Email Address')
    end
  end

  scenario 'As a regular instructor with a regular course,' \
           'I can see links to add or remove students', js: true, driver: :headless_chrome do
    course_name = 'run_of_the_mill_course'
    open_course = create(:open_course, owner: instructor, program: program, name: course_name)
    section = create(:section, course: open_course, instructor: instructor)
    student = create(:student, schools: [school])
    create(:enrollment,
           user: student,
           section: section,
           sufficient_access: false)
    create(:attempt, user: student, section: section)
    allow(Maestro::StudentGracePeriod).to receive(:all_for_course).and_return([])
    allow(Maestro::UserAccess).to receive(:immediate_access_revoke_list).and_return({})
    step 'I log in' do
      initialize_program_access_client_calls_for_instructor(instructor, program)
      log_in_as(instructor)
    end
    step 'I go to the section roster page' do
      visit section_roster_path(program, section, course_id: open_course.id)
    end
    step 'I see links to add and remove students' do
      expect(page).to have_selector('.js-add-students')
      expect(page).to have_selector('.js-drop-students')
    end
    step 'I see the students emails' do
      expect(page).to have_selector('th', text: 'Email Address')
    end
  end
end
