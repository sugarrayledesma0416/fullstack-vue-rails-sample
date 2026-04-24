feature 'edit section modal', js: true, chrome: true do
  include RspecJsCommonHelpers
  include CapybaraViewHelpers
  let!(:institution_admin) { create(:institution_admin) }
  let!(:instructor_1) { create(:instructor) }
  let!(:instructor_2) { create(:instructor) }
  let(:all_instructors) do
    {
      instructor_ids: [institution_admin.id, instructor_1.id, instructor_2.id],
      instructor_guids: [institution_admin.guid, instructor_1.guid, instructor_2.guid]
    }
  end
  let(:program) { create(:program) }
  let!(:school) { create(:school) }
  let(:enterprise_section) do
    create(:enterprise_section, instructor: institution_admin)
  end
  let!(:enterprise_course) do
    create(
      :course,
      owner: institution_admin,
      school:,
      is_enterprise: true,
      program_id: program.id,
      enterprise_section:,
      created_at: Time.zone.now - 10.minutes)
  end
  let(:section) do
    create(:section,
           name: 'My Section',
           instructor: institution_admin
           )
  end
  let(:instructor_options) do
    [
      { id: instructor_1.id, full_name: instructor_1.full_name, email: instructor_1.email },
      { id: instructor_2.id, full_name: instructor_2.full_name, email: instructor_2.email }
    ]
  end

  before do
    log_in_as(institution_admin)
    allow(Maestro::School).to receive(:instructors).and_return(all_instructors)
    allow_any_instance_of(InstitutionAdminDashboardPresenter)
      .to receive(:additional_instructor_options)
      .with(enterprise_course).and_return(instructor_options)
  end

  scenario 'As an institution admin' do
    enterprise_course.sections << section
    purpose 'I can edit a section' do
      step 'I go to the enterprise course detail page' do
        visit institution_admin_sections_path(
          program_id: program.id,
          school_id: school.id,
          course_id: enterprise_course.id
        )
        expect(page).to have_content(enterprise_course.name)
      end
      step 'I open the actions menu and click edit' do
        find('.c-menubar').hover
        click_on 'Edit'
      end
      step 'I see the edit modal' do
        expect(page).to have_content('Edit Section')
      end
      step 'I can see the current section data' do
        within('.js-edit-section-form') do
          section_name = find('#section_name')
          expect(section_name.value).to eq(section.name)

          section_owner = find('#course_owner')
          expect(section_owner.value).to eq("#{section.instructor.full_name} (#{section.instructor.email})")

          owner_visibility = find('#show_course_owner').value == 'true'
          expect(owner_visibility).to eq(!section.hide_owner_name)

          expect(page).not_to have_css('select.test-additional-instructor')
          expect(page).not_to have_css('select.test-additional-instructor-role')

          open_enrollment = find('#section_open_to_students').value == 'true'
          expect(open_enrollment).to eq(section.open_to_students)

          assignment_availability = find('#days_to_show_assignment_due_date').value
          days_to_show_assignment_due_date = assignment_availability == '' ? nil : assessment_availability.to_i
          expect(days_to_show_assignment_due_date).to eq(section.days_to_show_assignment_due_date)

          due_date_hour = find('#due_date_hour').value
          due_date_min = find('#due_date_min').value
          due_date_ampm = find('#due_date_ampm').value

          due_time = "#{due_date_hour}:#{due_date_min} #{due_date_ampm}"
          section_due_time = section.due_time.strftime("%I:%M %p")
          expect(due_time).to eq(section_due_time)

          timezone = find('#time_zone')
          expect(timezone.value).to eq(section.time_zone)
        end
      end
      step 'I change the name of the section' do
        within('.js-edit-section-form') do
          fill_in 'section_name', with: 'Renamed Section'
        end
      end
      step 'I see a button to add additional instructors' do
        within('.js-edit-section-form') do
          click_button 'Add additional instructor'
          expect(page).to have_css('select.test-additional-instructor')
          expect(page).to have_css('select.test-additional-instructor-role')
        end
      end
      step 'I add an additional instructor with assistant role' do
        within('.js-edit-section-form') do
          select "#{instructor_1.full_name} (#{instructor_1.email})", from: 'additional_instructor_1'
          select 'Assistant', from: 'instructor_role_1'
          page.execute_script("arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", first(:button, 'Save'))
          save_button = find(:button, 'Save')
          save_button.click
        end
      end
      step 'I see a flash message indicating that changes were succesfully applied' do
        expect_flash_message(
          'notice',
          "Section Renamed Section for Course #{enterprise_course.name} was updated successfully."
        )
        extra_instructors = Section.find(section.id).additional_instructors
        expect(extra_instructors.count).to eq(1)
        expect(extra_instructors.first.user_id).to eq(instructor_1.id)
        expect(extra_instructors.first.role).to eq('Assistant')
      end
    end
  end
end
