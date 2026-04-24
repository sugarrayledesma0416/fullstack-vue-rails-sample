include RspecJsCommonHelpers
include RspecJsApiHelpers
include RspecJsContentHelpers

feature 'Check user access', js: true, chrome: true do
  let(:school) { create(:school) }
  let(:regular_student) { create(:student) }
  let(:cartridge_student) { create(:cartridge_user) }
  let(:program) { create(:program) }
  let(:activity) do
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'drop_down_table.xml'),
      program,
      grading_method: 'auto'
    )
  end
  let(:section) { create(:section, course: course) }
  let(:course) { create(:course, program: program) }

  before do
    create(:active_enrollment, user: cartridge_student, section: section)
    create(:active_enrollment, user: regular_student, section: section)
    create(:school_user, user: cartridge_student, school: school)
    create(:cartridge_student_user_link, user: cartridge_student, school: school)
    activity.license_group_id = 2
    activity.save
  end

  scenario 'User is cartridge' do
    step 'Login as student' do
      give_user_access_to_program(cartridge_student, program)
      log_in_as(cartridge_student)
    end

    step 'Redirect to cartridge_access_denied_path' do
      visit section_activity_path(section, activity)
      expect(page).to have_selector('.test-cartridge-access-denied')
    end
  end

  scenario 'User is not cartridge' do
    step 'Login as student' do
      give_user_access_to_program(regular_student, program)
      log_in_as(regular_student)
    end

    step 'Does not redirect to cartridge_access_denied_path' do
      visit section_activity_path(section, activity)
      expect(page).not_to have_selector('.test-cartridge-access-denied')
    end
  end
end
