feature 'Instructor section setup', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include GradebookEngineHelpers
  include Capybara::Angular::DSL
  include CapybaraViewHelpers

  let(:school) { create(:school) }
  let(:instructor) { create(:instructor, last_name: 'Zounds', schools: [school]) }
  let(:instructor_1) { create(:instructor, last_name: 'Yclept', schools: [school]) }
  let(:instructor_2) { create(:instructor, last_name: 'Xylops', schools: [school]) }
  let(:program) { create(:vol_program) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let!(:default_section) do
    create(
      :section,
      additional_info: 'More info',
      course: course,
      instructor: instructor
    )
  end
  let (:additional_info) { 'Information about this section' }
  let(:course_licenses) { [] }
  let(:save_button_selector) { '#save-button' }
  let(:add_section_selector) { '.add_section' }
  let(:course_with_assignment) do
    create(:course, owner: instructor, program: program)
  end
  let(:section_with_assignment) do
    create(:section, instructor: instructor, course: course_with_assignment)
  end
  let(:activity) { create_open_ended_activity(program) }
  let!(:assignment) do
    create(
      :assignment,
      assignable: activity,
      current: true,
      section: section_with_assignment
    )
  end
  let(:course_ext_item) { create(:course, owner: instructor, program: program) }
  let(:section_ext_item) do
    create(:section, instructor: instructor, course: course_ext_item)
  end
  let(:external_activity) { create(:gb_external_activity, school_id: school.id) }

  before do
    create(
      :gb_external_assignment,
      category_id: assignment.category_id,
      external_activity: external_activity,
      lesson_id: activity.lesson_id,
      section_id: section_ext_item.id
    )

    initialize_program_access_client_calls_for_instructor(instructor, program)
    course_licenses << Maestro::CourseLicense.new('license_group' => { 'id' => 1, 'demo' => false })
    allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)
    allow(Maestro::School).to receive(:instructors).and_return(
      'instructor_ids' => [instructor.id, instructor_1.id, instructor_2.id],
      'instructor_guids' => [instructor.guid, instructor_1.guid, instructor_2.guid]
    )
    log_in_as(instructor)
  end

  def set_section_name(name)
    fill_in('section_name', with: name)
  end

  def set_additional_section_info(info)
    fill_in('section_additional_info', with: '')
    fill_in('section_additional_info', with: info)
  end

  def save_button_disabled
    expect(
      find('button[type="submit"]', visible: true)
    ).to be_disabled
  end

  def save_button_not_disabled
    expect(
      find('button[type="submit"]', visible: true)
    ).not_to be_disabled
  end

  def expect_due_time(hour, min, ampm)
    expect(page).to have_selector('#due_time_hour', text: hour)
    expect(page).to have_selector('#due_time_min', text: min)
    expect(page).to have_selector('#due_time_ampm', text: ampm)
  end

  def expect_time_zone(timezone)
    expect(page).to have_selector('#section_time_zone', text: timezone)
  end

  def expect_text_section_preview(info)
    expect(page).to have_selector('.test-section-row-preview', text: info)
  end

  def expect_no_text_section_preview(info)
    expect(page).to have_no_selector('.test-section-row-preview', text: info)
  end

  def select_due_time(hour, min, ampm)
    select hour, from: 'due_time_hour'
    select min, from: 'due_time_min'
    select ampm, from: 'due_time_ampm'
  end

  def select_due_timezone(timezone)
    select timezone, from: 'section_time_zone'
  end

  def click_section_selector(course_id)
    within(".test-course-info-#{course_id}-wrapper") do
      find('.test-section-add-link').click
    end
  end

  def follow_edit_link_from_gear_menu(section_id)
    within("#section_#{section_id}") do
      step 'Click on the gear of the section' do
        find('.test-gear').click
      end
      step 'Click on the "Edit Section" link' do
        click_link('Edit Section')
      end
    end
  end

  # This scenario needs to be updated to take into account major changes
  # to the css and functionality of the instructor dashboard. It would be
  # best if it were borken up into several discrete scenarios. That way
  # a nondeterministic failure in one test won't result in the all the
  # coverage getting thrown out.
  xscenario 'Instructor section setup', nondeterministic: true do
    step 'Visit the dashboard page' do
      visit instructor_dashboard_path(program.id)
    end

    purpose 'I can create a new section' do
      purpose 'I can cancel the procedure at any time' do
        step 'Click on the "Add section" link' do
          click_section_selector(course.id)
        end
        step 'Click the "cancel" button' do
          wait_for_ajax
          find('.test-cancel-button').click
        end
        step 'I am back to the dashboard' do
          expect_url(instructor_dashboard_path(program.id))
        end
        step 'Click on the "Add section" link' do
          click_section_selector(course.id)
        end
        step 'Set a section name' do
          wait_for_ajax
          set_section_name('Sample Section')
        end
        accept_alert { find('.test-cancel-button').click }
      end

      purpose 'A section name is required' do
        step 'Click on the "Add section" link' do
          click_section_selector(course.id)
        end
        step 'The "save" button is disabled' do
          wait_for_ajax
          save_button_disabled
        end
        step 'Set a section name' do
          set_section_name('Sample Section')
        end
        step 'The "save" button is enabled' do
          save_button_not_disabled
        end
        step 'Delete the section name' do
          set_section_name('')
        end
        step 'I see the message "Section name is required."' do
          expect(find('#empty_section_name')).to have_text('Section name is required.')
        end
        step 'The "save" button is disabled' do
          save_button_disabled
        end
        accept_alert { find('.test-cancel-button').click }
      end

      purpose 'Section name cannot be longer than 75 characters' do
        step 'Click on the "Add section" link' do
          click_section_selector(course.id)
        end
        step 'Set a section name of 75 characters' do
          set_section_name('111111111122222222223333333333444444444455555555556666666666777777777788888')
        end
        step 'I see no message "Your section name cannot be longer than 75 characters."' do
          expect(page).to have_no_selector(
            '#invalid_section_name',
            text: 'Your section name cannot be longer than 75 characters.',
            visible: true
          )
        end

        step 'The "save" button is enabled' do
          save_button_not_disabled
        end
        step 'Set a section name of 76 characters' do
          set_section_name('1111111111222222222233333333334444444444555555555566666666667777777777888888')
        end
        step 'I see the message "Your section name cannot be longer than 75 characters."' do
          expect(page).to have_selector(
            '#invalid_section_name',
            text: 'Your section name cannot be longer than 75 characters.',
            visible: true
          )
        end
        accept_alert { find('.test-cancel-button').click }
      end

      purpose 'Student preview is unavailable if I am a Clever rostering user' do
        step 'Mock rostering status as true' do
          allow(instructor).to receive(:rostering?).and_return(true)
          allow_any_instance_of(Instructor::SectionsController)
          .to receive(:current_user)
          .and_return(instructor)
        end
        step 'Click on the "Add section" link' do
          click_section_selector(course.id)
        end
        step 'Assert absence of preview button' do
          expect(page).not_to have_text('Preview as student')
        end
        step 'Mock rostering status as false' do
          allow(instructor).to receive(:rostering?).and_return(false)
        end
        find('.test-cancel-button').click
      end

      purpose 'Additional section information cannot be longer than 255 characters' do
        step 'Click on the "Add section" link' do
          click_section_selector(course.id)
        end
        step 'Set a section name' do
          set_section_name('Section 1')
        end
        section_info = 'testtext' * 32
        step 'Set additional section information of 256 characters' do
          set_additional_section_info(section_info)
        end
        step 'The additional section information are clamped to 255 characters' do
          expect(find('#section_additional_info').value).to eq(section_info[0, 255])
        end
      end

      purpose 'I see a preview of how my students will see the section' do
        purpose 'I do not initially see a preview' do
          step 'Assert absence of preview' do
            expect(page).not_to have_selector('.test-section-preview', visible: true)
          end
        end

        purpose 'I can hover on link to show preview' do
          step 'Click to show preview' do
            find('.test-student-preview-link').click
            expect(page).to have_selector('.test-section-preview', visible: true)
          end
        end
        step 'I see the message "When your students enroll, they will see this."' do
          expect(page).to have_selector(
            '.test-preview-table-caption',
            text: 'When your students enroll, they will see this:'
          )
        end
        step 'I see a table containing a preview of the section I am creating' do
          step 'I see basic information' do
            step 'I see the name of the instructor' do
              expect_text_section_preview(instructor.last_name_first)
            end
            step 'I see the name of the course' do
              expect_text_section_preview(course.name)
            end
            step 'I see the name of the section' do
              section_name = find('#section_name').value
              expect_text_section_preview(section_name)
           end
            set_additional_section_info(additional_info)
          end
        end
        step 'I can hide the section preview' do
          step 'Unhover to hide preview' do
            find('.test-student-preview-link').click
            expect(page).not_to have_selector('.test-section-preview', visible: true)
          end
        end
      end

      purpose 'I can use default settings' do
        step 'Expect no dropdown for previous sections' do
          expect(page).not_to have_selector('.test-copy-assignment', visible: true)
        end
        step 'I do not see a warning message' do
          expect(page).to_not have_selector('.test-flash-warning')
        end
        step 'Set Additional section information' do
          section_info = 'This is the additional information'
          set_additional_section_info(section_info)
          expect(find('#section_additional_info').value).to eq(section_info)
        end
        step 'Due date is set to 11:59PM' do
          expect_due_time('12', '00', 'PM')
        end
        step 'Time zone is set to GMT-05:00' do
          timezone = '(GMT-05:00) Eastern Time (US & Canada)'
          expect_time_zone(timezone)
        end
      end

      purpose 'I do not see a dropdown if there are no assignments in the previous section' do
        step 'There is no menu to copy if the section has no assignments' do
          expect(page).to_not have_selector('.test-copy-assignment')
        end
        step 'The option to copy external assignments is not present' do
          expect(page).not_to have_selector('.test-copy-ext-assignment', visible: true)
        end
        step 'Other information is not copied from the existing section' do
          expect(find('#section_additional_info').value).to eq('This is the additional information')
        end
      end

      purpose 'I can change the due time' do
        step 'Set the due time to "10:30 AM"' do
          select_due_time('10', '30', 'AM')
        end
        step 'I see the due time "10:30 AM"' do
          expect_due_time('10', '30', 'AM')
        end
      end

      purpose 'I can change the time zone' do
        step 'Select the time zone in "Hawaii"' do
          select_due_timezone('(GMT-10:00) Hawaii')
        end
        step 'I see the time zone in "Hawaii"' do
          expect_time_zone('(GMT-10:00) Hawaii')
        end
      end

      purpose 'I can set the assignment availability days' do
        step 'Expand the assignment availability section' do
          find('.test-assignment-availability').click
        end
        step 'Select an amount of days' do
          select '1 Week', from: 'days_to_show_assignment_due_date'
        end
      end

      purpose 'I can choose to not allow new students to enroll in this course section' do
        step 'Uncheck the checkbox "Allow new students to enroll in this course section"' do
          find('label[for="section_open_to_students"]').click
        end
      end

      purpose 'I can add team members' do
        step 'Expand the additional instructor(s) section' do
          find('.test-instructor-names-disclosure').click
        end
        step 'Select an instructor as co-instructor' do
          # Make the second instructor in the list (Yclept) the co-instructor
          #   so that we can assert correct ordering after all roles are selected.
          page.all('.test-section-instructor-roles')[1].find(:option, 'Co-instructor').select_option
        end
        step 'Select an instructor as assistant' do
          # Make the first instructor in the list (Xylops) the assistant.
          page.all('.test-section-instructor-roles')[0].find(:option, 'Assistant').select_option
        end
      end

      purpose 'I see instructors listed in the expected order' do
        step 'I see instructor/co-instructor/assistant in that order under "Instructor"' do
          expected_instructor_names = [
            # Zounds should be first;
            "Instructor #{instructor.full_name} #{instructor.email}",
            # Yclept should be second;
            "Co-instructor #{instructor_1.full_name} #{instructor_1.email}",
            # Xylops should be third.
            "Assistant #{instructor_2.full_name} #{instructor_2.email}"
          ]
          expect(
            find_all('.test-instructor-detail').map { |name| name.text.gsub(/\n/, ' ').strip }
          ).to eq(expected_instructor_names)
        end
        step 'I see additional instructors in alpha order under "Additional Instructor(s)"' do
          expected_additional_instructor_names = [instructor_2, instructor_1].map do |instructor|
            "#{instructor.full_name} (#{instructor.email})"
          end
          expect(find_all('.test-additional-instructor-name').map(&:text))
          .to eq(expected_additional_instructor_names)
        end
      end

      purpose 'I can select the days the section meets' do
        step 'Select Monday and Friday' do
          find('label', text: 'Mon').click
          find('label', text: 'Fri').click
        end
      end

      purpose 'I see additional instructors in the preview' do
        step 'I see my name and the name of the additional instructors in the preview' do
          # Instructor, co-instructor, and assistant should each be "last name, first name",
          #   all joined with commas.
          instructors_in_preview = [instructor, instructor_1, instructor_2]
          expect_text_section_preview(instructors_in_preview.map(&:last_name_first).join(', '))
        end
      end

      purpose 'I can choose to not show my name to students' do
        step 'Select the checkbox to not show my name to students' do
          find('label[for="hide_owner_name"]').click
        end
        step 'I do not see my name in the preview' do
          expect_no_text_section_preview(instructor.last_name)
          expect_no_text_section_preview(instructor.first_name)
        end
      end

      purpose 'I do not need to select days the section meets' do
        step 'The "save" button is enabled' do
          save_button_not_disabled
        end
      end

      purpose 'I can select the days the section meets' do
        step 'Select Monday and Friday' do
          check('Mon')
          check('Fri')
        end
      end

      purpose 'I can save the section' do
        step 'Click on the "save" button' do
          find('button[type="submit"]', visible: true).click
        end

        step 'I see the flash message "Your new section has been created."' do
          expect_flash_message('notice', 'Your new section has been created.')
        end
      end
    end

    created_section = Section.last
    purpose 'The section has been created' do
      expect(created_section).to have_attributes(
        name: 'Section 1'
      )
    end

    purpose 'I can copy assignments and due dates from an existing section with assignments' do
      step 'Return to the instructor dashboard' do
        visit instructor_dashboard_path(program.id)
      end
      step 'Add a section in a course that has a section with assignments' do
        click_section_selector(course_with_assignment.id)
      end
      step 'Select a section from the "Copy assignments from section" dropdown' do
        select section_with_assignment.name, :from => "previous_section_id"
      end
      step 'I see a warning message' do
        assignment_copy_message = find(".test-flash-warning")
        expect(assignment_copy_message).to be_visible
        expect(assignment_copy_message).to have_text("All assignments, due dates and assessment details will be copied from section #{section_with_assignment.name}.")
      end
    end

    purpose 'I am given the option to copy external assignments from an existing section' do
      step 'Return to the instructor dashboard' do
        visit instructor_dashboard_path(program.id)
      end
      step 'Select a section with an external assignment' do
        click_section_selector(course_ext_item.id)
      end
      step 'Select a section with external assignments from the "Copy assignments from section" dropdown' do
        select section_ext_item.name, from: "previous_section_id"
      end
      step 'The option to copy external assignments is present' do
        expect(page).to have_selector('.test-copy-ext-assignment', visible: true)
      end
    end

    purpose 'I can edit a section' do
      visit instructor_dashboard_path(program.id)
      follow_edit_link_from_gear_menu(created_section.id)
      wait_for_ajax

      step 'Information in the "section information" tab is set' do
        step 'The name is set' do
          expect(find('#section_name').value).to eq('Section 1')
        end
        step 'The additional section information is set' do
          expect(find('#section_additional_info').value).to eq('This is the additional information')
        end
        step 'the due date is set' do
          expect_due_time('10', '30', 'AM')
        end
        step 'The time zone is set' do
          expect_time_zone('Hawaii')
        end
        step 'Expand the assignment availability section' do
          find('.test-assignment-availability').click
        end
        step 'The amount of days available before due date is set' do
          expect(page).to have_selector('#days_to_show_assignment_due_date', text: '1 Week')
        end
        step 'The check box "Allow new students to enroll in this course section" is unchecked' do
          expect(find('#section_open_to_students')).not_to be_checked
        end
        step 'Expand the additional instructor(s) section' do
          find('.test-instructor-names-disclosure').click
        end
        # FIXME: sleep is bad, but nothing else is working.
        sleep 1

        step 'The first instructor is marked as an assistant' do
          # instructor_2 (Xylops) appears first alphabetically
          #   and is an assistant.
          expect(page.find_all('.instructor_role select')[0].value).to eq('Assistant')
        end
        step 'The second instructor is marked as a co-instructor' do
          # instructor_1 (Yclept) appears second alphabetically
          #   and is a co-instructor.
          expect(page.find_all('.instructor_role select')[1].value).to eq('Co-instructor')
        end
      end

      step 'Class-days information is set' do
        step 'The section days are selected' do
          step 'Monday checkbox is checked' do
            expect(find('[data-js-day-name="Mon"]')).to be_checked
          end
          step 'Friday checkbox is checked' do
            expect(find('[data-js-day-name="Fri"]')).to be_checked
          end
        end
      end

      purpose 'I can only save changes if I make some modification' do
        step 'The "save changes" is disabled' do
          save_button_disabled
        end
        step 'Uncheck Monday' do
          find('label[for="section_days_Mon"]').click
        end
        step 'The "save changes" is enabled' do
          save_button_not_disabled
        end
      end

      purpose 'I can update all the section information' do
        step 'Set a new name' do
          wait_for_ajax
          set_section_name('New Section')
        end
        step 'Set new additional section information' do
          section_info = 'New Additional Information'
          set_additional_section_info(section_info)
        end
        step 'Set a new due date' do
          select_due_time('11', '00', 'AM')
        end
        step 'Set a new time zone' do
          select_due_timezone('(GMT-06:00) Mexico City')
        end
        step 'Remove additional instructors' do
          # The Additional Instructors disclosure is already visible
          #   from an earlier expansion.
          page.all('.test-section-instructor-roles')[0].find(:option, '').select_option
          page.all('.test-section-instructor-roles')[1].find(:option, '').select_option
        end
        step 'Click on the "save changes" button' do
          find('button[type="submit"]', visible: true).click
        end
        step 'I see the flash message "Section has been successfully updated."' do
          expect_flash_message('notice', 'Section has been successfully updated.')
        end
      end

      purpose 'Section information has been updated' do
        follow_edit_link_from_gear_menu(created_section.id)
        step 'All the section information is set' do
          step 'The name is set' do
            wait_for_ajax
            expect(find('#section_name').value).to eq('New Section')
          end
          step 'The additional section information is set' do
            expect(find('#section_additional_info').value).to have_text(
              'New Additional Information'
            )
          end
          step 'the due date is set' do
            expect_due_time('11', '00', 'AM')
          end
          step 'The time zone is set' do
            expect_time_zone('Mexico City')
          end
          step 'The check box "Allow new students to enroll in this course section" is unchecked' do
            expect(find('#section_open_to_students')).not_to be_checked
          end
          step 'Expand the additional instructor(s) section' do
            find('.test-instructor-names-disclosure').click
          end
          step 'No Additional Instructor is present' do
            expect(page.find_all('.instructor_role select')[0].value).to eq('')
            expect(page.find_all('.instructor_role select')[1].value).to eq('')
          end
        end
      end
    end

    section_selector = "#section_#{created_section.id}"
    purpose 'I see a warning when trying to delete a section' do
      visit instructor_dashboard_path(program.id)
      within(section_selector) do
        step 'Click on the gear of the section' do
          find('.test-gear').click
        end
        step 'Click on the "Delete Section" link' do
          within(".js-delete-section-#{created_section.id}") do
            find('.test-section-del-link').click
          end
        end
      end
      step 'I see a modal saying that this action cannot be undone' do
        expect(page).to have_text('This action cannot be undone')
      end
      step 'Click on the "cancel" button' do
        within(".js-section-#{created_section.id}-modal") do
          find('.c-linkish').click
        end
      end
    end

    purpose 'I can see a confirmation message when I delete a section' do
      within(section_selector) do
        step 'Click on the "Delete Section" link' do
          within(".js-delete-section-#{created_section.id}") do
            find('.test-section-del-link').click
          end
        end
      end
      step 'Click on the "delete" button' do
        within(".js-section-#{created_section.id}-modal") do
          click_button('Delete')
        end
      end
      step 'I see the flash message "Section xxx was deleted successfully."' do
        find('div#dashboard')
        expect_flash_message('notice', 'Section New Section was deleted successfully.')
      end
    end
  end
end
