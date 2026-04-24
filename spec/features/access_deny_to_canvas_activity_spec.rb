feature 'visit an activity in canvas', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  given(:instructor) { create(:cartridge_instructor) }
  given(:student) { create(:cartridge_student) }
  given(:section) { create(:section) }
  given(:program) { section.program }
  given(:activity) do
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'drop_down_table.xml'),
      program,
      grading_method: 'auto'
    )
  end
  given(:school) { create(:school) }

  background do
    create(:school_user, user: instructor, school: school)
    create(:school_user, user: student, school: school)
    create(:active_enrollment, user: student, section: section)
    create(:cartridge_instructor_user_link, user: instructor, school: school)
    create(:cartridge_student_user_link, user: student, school: school)
  end

  scenario 'redirect an instructor to the access denied activity page' do
    purpose 'when a cartridge instructor does not have a site license' \
      'it is redirected to the access_denied view' do

      step 'login as a cartridge instructor' do
        initialize_client_calls_for_user(instructor)
        log_in_as(instructor)
      end

      step 'visit an activity' do
        visit cartridge_section_activity_path(section, activity)

        expect(page).to have_selector('.test-cartridge-access-denied')
        expect(page).to have_current_path cartridge_access_denied_path(activity)
      end
    end
  end

  scenario 'the show activity page is rendered for an instructor' do
    purpose 'when a cartridge instructor does have a site license' \
      'the show view is rendered' do

      step 'login as a cartridge instructor' do
        log_in_as(instructor)
        give_user_access_to_program(instructor, activity.program)
      end

      step 'visit an activity' do
        visit cartridge_section_activity_path(section, activity)

        expect(page).not_to have_selector('.test-cartridge-access-denied')
        expect(page).to have_current_path cartridge_section_activity_path(section, activity)
      end
    end
  end

  scenario 'redirect a student to the access denied activity page' do
    purpose 'when a cartridge student does not have a site license' \
      'it is redirected to the access_denied view' do

      step 'login as a cartridge student' do
        initialize_client_calls_for_user(student)
        log_in_as(student)
      end

      step 'visit an activity' do
        visit cartridge_section_activity_path(section, activity)

        expect(page).to have_selector('.test-cartridge-access-denied')
        expect(page).to have_current_path cartridge_access_denied_path(activity)
      end
    end
  end


  scenario 'the show activity page is rendered for a student' do
    purpose 'when a cartridge student does have a site license' \
      'the show view is rendered' do

      step 'login as a cartridge instructor' do
        give_user_access_to_program(student, activity.program)
        log_in_as(student)
      end

      step 'visit an activity' do
        visit cartridge_section_activity_path(section, activity)

        expect(page).not_to have_selector('.test-cartridge-access-denied')
        expect(page).to have_current_path cartridge_section_activity_path(section, activity)
      end
    end
  end
end
