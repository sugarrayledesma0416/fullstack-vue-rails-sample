feature 'Instructor dashboard course and section management',
  chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  let(:school_1) { create(:school, name: 'school 1') }
  let(:instructor) { create(:instructor) }
  let(:district) { create(:district, name: 'district_school') }
  let(:program) { create(:vol_program_with_toc_entries) }
  let(:program_settings) do
    {
      content_menu_additional_entries: [
        { label: 'External student link', url: 'http://student.com', target_user: 'Student' },
        { label: 'External instructor link', url: 'http://instructor.com', target_user: 'Instructor' }
      ]
    }
  end

  let(:program_settings_hide) do
    {
      content_menu_additional_entries: [
        { label: 'External student link', url: 'http://student.com', target_user: 'Student' },
        { label: 'External instructor link', url: 'http://instructor.com', target_user: 'Instructor' }
      ],
      hide_activities: true,
      hide_my_content: true
    }
  end

  scenario 'As an instructor with school, course and section, I can re-arrange ' \
    'and organize schools, courses, and sections on my dashboard',
    nondeterministic: true do
      pending
      raise 'This is a non-deterministic failure'
    def within_school_listing(school)
      within(".test-school-#{school.id}") { yield }
    end

    def within_course_listing(course)
      within(".test-course-#{course.id}-wrapper") { yield }
    end

    def within_section_listing(section)
      within("#section_#{section.id}") { yield }
    end

    def within_course_summary
      within('#column_two') { yield }
    end

    def expect_flash(type, message)
      flash = find(".test-flash-#{type}")
      expect(flash).to be_visible
      expect(flash).to have_text(message)
    end

    def navigate_away
      find('.c-heading--page-title').click
    end

    def section_gear(section)
      navigate_away
      find("#section_#{section.id} .test-section-gear")
    end

    course_1_1 = create(
      :course,
      name: 'course_1_1', school: school_1, owner: instructor, program: program
    )
    sec_1_1_1 = create(
      :section, name: 'sec_1_1_1', course: course_1_1, instructor: instructor
    )
    sec_1_1_2 = create(
      :section, name: 'sec_1_1_2', course: course_1_1, instructor: instructor
    )

    course_1_2 = create(
      :course, name: 'course_1_2', school: school_1, program: program
    )
    sec_1_2_1 = create(
      :section, name: 'sec_1_2_1', course: course_1_2, instructor: instructor
    )
    create(
      :section, name: 'sec_1_2_2', course: course_1_2
    )

    course_1_3 = create(
      :course,
      name: 'course_1_3', school: school_1, owner: instructor, program: program
    )

    course_template = create(
      :course,
      name: 'course_template',
      is_template: true,
      owner: instructor,
      program: program,
      school: school_1,
    )

    school_2 = create(:school, name: 'school 2')
    course_2_1 = create(
      :course,
      name: 'course_2_1', school: school_2, owner: instructor, program: program
    )
    sec_2_1_1 = create(
      :section,
      name: 'sec_2_1_1', course: course_2_1, instructor: instructor
    )
    sec_2_1_2 = create(
      :section,
      name: 'sec_2_1_2', course: course_2_1, instructor: instructor
    )

    course_package = Maestro::CoursePackage.new(
      'content_type' => 'level', 'id' => 1, 'name' => 'Supersite'
    )
    create(:vol_program_config, program: program)
    create(:school_user, user: instructor, school: school_1)
    @course_packages_by_course = {}
    [course_1_1, course_1_2, course_1_3, course_2_1].each do |course|
      @course_packages_by_course[course.guid] = [course_package]
    end

    allow(Maestro::School).to receive(:instructors).and_return(
      'instructor_ids' => [instructor.id],
      'instructor_guids' => [instructor.guid]
    )
    allow(Maestro::CoursePackage).to receive(:all).and_return([])
    allow(Maestro::CoursePackage).to receive(:all_for_courses)
      .and_return(@course_packages_by_course)
    allow(Maestro::CoursePackage).to receive(:all_for_course) do
      [course_package]
    end
    allow(Maestro::CoursePackage).to receive(:available_packages)
      .and_return([course_package])

    before do
      create(:school_user, user: instructor, school: district)
    end

    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    visit instructor_dashboard_path(program.id)

    purpose 'Courses are organized by school' do
      purpose 'Within "school 1"' do
        step 'I see course "course_1_1"' do
          expect(page).to have_content('course_1_1')
        end
        step 'I see section "sec_1_1_1"' do
          expect(page).to have_content('sec_1_1_1')
        end
        step 'I see section "sec_1_1_2"' do
          expect(page).to have_content('sec_1_1_2')
        end
        step 'I see course "course_1_2"' do
          expect(page).to have_content('course_1_2')
        end
        step 'I see section "sec_1_2_1"' do
          expect(page).to have_content('sec_1_2_1')
        end
        step 'I do not see section "sec_1_2_2"' do
          expect(page).not_to have_content('sec_1_2_2')
        end
        step 'I see course "course_1_3"' do
          expect(page).to have_content('course_1_3')
        end

        purpose 'I do not see course templates' do
          expect(page).not_to have_content('course_template')
        end
      end
      purpose 'Within "school 2"' do
        step 'I see course "course_2_1"' do
          expect(page).to have_content('course_2_1')
        end
        step 'I see section "sec_2_1_1"' do
          expect(page).to have_content('sec_2_1_1')
        end
        step 'I see section "sec_2_1_2"' do
          expect(page).to have_content('sec_2_1_2')
        end
      end
    end
    purpose 'Instructor has district school but it is not shown in the school list' do
      step 'instructor is part of the district school' do
        expect(instructor.schools).to include(district)
      end
      step 'school list does not contain the district school' do
        expect(page).not_to have_content('district_school')
      end
    end
    purpose 'The first course is selected' do
      step 'The focus is set to "course_1_1"' do
        within('.test-courses-by-school.program-header-bar') do
          expect(page).to have_content('course_1_1')
        end
      end
    end
    purpose 'I can select a course from the focus widget' do
      step 'Click on the focus widget' do
        find('#focus_indicator').click
      end
      step 'Select "course_2_1"' do
        within('#focus_menu_container') { click_link('course_2_1') }
      end
      step 'The focus is set to "course_2_1"' do
        within('.test-courses-by-school.program-header-bar') do
          expect(page).to have_content('course_2_1')
          expect(page).not_to have_content('course_1_1')
        end
      end
    end
    purpose 'I can select a section from the focus widget' do
      step 'Click on the focus widget' do
        find('#focus_indicator').click
      end
      step 'Select "sec_1_1_2"' do
        within('#focus_menu_container') { click_link('sec_1_1_2') }
      end
      step 'The focus is set to "sec_1_1_2"' do
        selected_section = find("#section_#{sec_1_1_2.id}")
        expect(selected_section[:class]).to have_content('program-header-bar')
      end
    end
    purpose 'I can collapse a school' do
      step 'collapse the accordion of "school 1"' do
        find(".test-school-header-#{school_1.id} .school_accordion").click
      end
      step 'I cannot see course "course_1_1"' do
        within_school_listing(school_1) { expect(page).not_to have_content('course_1_1') }
      end
      step 'I cannot see course "course_1_2"' do
        within_school_listing(school_1) { expect(page).not_to have_content('course_1_2') }
      end
      step 'expand the accordion of "school 1"' do
        find(".test-school-header-#{school_1.id} .school_accordion").click
      end
    end
    purpose 'When selecting a course, I see a summary of every section in this course' do
      step 'Select the course "course_1_1"' do
        within_school_listing(school_1) { click_link('course_1_1') }
      end
      within_course_summary do
        step 'I see a summary of the section "sec_1_1_1"' do
          expect(page).to have_content('sec_1_1_1')
        end
        step 'I see a summary of the section "sec_1_1_2"' do
          expect(page).to have_content('sec_1_1_2')
          expect(page).to have_content('0.0% Section average 0 Students')
        end
      end
    end
    purpose 'When selecting a course with no section, I see a link to add a section' do
      step 'Select the course "course_1_3"' do
        within_school_listing(school_1) { click_link('course_1_3') }
      end
      within_course_summary { click_link('Click here to add a section') }
      click_button('cancel')
    end
    purpose 'When selecting a section I see its details' do
      step 'Select the section "sec_1_1_1"' do
        within_school_listing(school_1) { click_link('sec_1_1_1') }
      end
      within_course_summary do
        step 'I see detailed information for the section "sec_1_1_1"' do
          expect(page).to have_content('sec_1_1_1')
          expect(page).to have_content('0.0% Section average 0 Students')
        end
        step 'I do not see any information for the section "sec_1_1_2"' do
          expect(page).not_to have_content('sec_1_1_2')
        end
      end
    end
    purpose 'I can add a course to a school' do
      step 'Click on the "add course" link in school "school 1"' do
        within(".test-school-header-#{school_1.id}") { click_link('ADD COURSE') }
      end
      click_link('cancel')
    end
    purpose 'I can add a section to a course' do
      step 'Click on the "add section" link in course "course_1_1"' do
        within_course_listing(course_1_1) { click_link('ADD SECTION') }
      end
      click_button('cancel')
    end
    purpose 'I can edit a course' do
      within_course_listing(course_1_1) do
        step 'Click on the gear of the course "course_1_1"' do
          find('.test-course-gear').click
        end
        step 'Click on the "Edit Course" link' do
          click_link('Edit Course')
        end
      end
      click_link('cancel')
    end
    purpose 'I cannot delete a course that has sections' do
      within_course_listing(course_1_1) do
        step 'Click on the gear of the course "course_1_1"' do
          find('.test-course-gear').click
        end
        step 'The "Delete course" link is disabled' do
          expect(page).to have_selector(
            '.test-gear-option .test-course-del-disable',
            text: 'Delete Course'
          )
        end
      end
    end
    purpose 'A section has a contextual menu' do
      step 'Every section has a gear next to its name' do
        [sec_1_1_1, sec_1_1_2, sec_1_2_1, sec_2_1_1, sec_2_1_2].each do |section|
          expect(section_gear(section)).not_to be_nil
        end
      end
      step 'Click on the gear of the section "sec_1_1_1"' do
        section_gear(sec_1_1_1).click
      end
      within_section_listing(sec_1_1_1) do
        expect(page).to have_link('Assignment Wizard')
        expect(page).to have_link('Edit Section')
        expect(find('.js-delete-link').value).to eq('Delete Section')
        expect(page).to have_link('Instructions for Students')
        expect(page).to have_link('Create Sample Student')
        expect(page).to have_link('Accessibility Guide')
      end
    end
    purpose 'I can open the assignment wizard for a section' do
      step 'Click on the gear of the section "sec_1_1_1"' do
        section_gear(sec_1_1_1).click
      end
      step 'Click on the "Assignment Wizard" link' do
        within_section_listing(sec_1_1_1) { click_link('Assignment Wizard') }
      end
      step 'Click on the "cancel" button' do
        find('.cancel-course-setup').click
      end
    end
    purpose 'I can edit a section' do
      step 'Click on the gear of the section "sec_1_1_1"' do
        section_gear(sec_1_1_1).click
      end
      within_section_listing(sec_1_1_1) { click_link('Edit Section') }
      click_button('cancel')
    end
    purpose 'I can create sample student' do
      step 'Click on the gear of the section "sec_1_1_1"' do
        section_gear(sec_1_1_1).click
      end
      step 'Click on the "Create Sample Student" link' do
        within_section_listing(sec_1_1_1) do
          click_link('Create Sample Student')
        end
      end
      step 'I see the flash message "Sample student created successfully."' do
        expect_flash('notice', 'Sample student created successfully.')
      end
    end

    # declare var outside blocks so it's in the right scope
    deletion_modal = nil
    purpose 'I can delete a section' do
      step 'Click on the gear of the section "sec_1_1_1"' do
        section_gear(sec_1_1_1).click
      end
      step 'Click on the "Delete section" link' do
        within_section_listing(sec_1_1_1) { find('.js-delete-link').click }
      end
      step 'I see a modal asking if I am sure' do
        deletion_modal = find(".js-delete-dialog.js-section-#{sec_1_1_1.id}-modal")
        expect(deletion_modal).to have_content('Are you sure you want to delete sec_1_1_1?')
      end
      step 'Click on the "cancel" button' do
        deletion_modal.find('.js-cancel-button').click
      end
      step 'Click on the gear of the section "sec_1_1_1"' do
        section_gear(sec_1_1_1).click
      end
      step 'Click on the "Delete section" link' do
        within_section_listing(sec_1_1_1) { find('.js-delete-link').click }
      end
      step 'Click on the "delete" button' do
        deletion_modal.click_button('Delete')
      end
      step 'I see the flash message "Section sec_1_1_1 was deleted successfully."' do
        expect_flash('notice', 'Section sec_1_1_1 was deleted successfully.')
      end
    end
    purpose 'I can delete a course with no section' do
      step 'Delete the section "sec_1_1_2"' do
        section_gear(sec_1_1_2).click
        within("#section_#{sec_1_1_2.id}") { find('.js-delete-link').click }
        within(".js-delete-dialog.js-section-#{sec_1_1_2.id}-modal") do
          click_button('Delete')
        end
      end
      within_course_listing(course_1_1) do
        step 'Click on the gear of the course "course_1_1"' do
          find('.test-course-gear').click
        end
        step 'Click on the "Delete course" link' do
          find('.test-course-del-link').click
        end
      end
      step 'I see a modal asking if I am sure' do
        deletion_modal = find(".js-delete-dialog.js-course-#{course_1_1.id}-modal")
        expect(deletion_modal).to have_content('Are you sure you want to delete course_1_1?')
      end
      step 'Click on the "cancel" button' do
        deletion_modal.find('.js-cancel-button').click
      end
      step 'Click on the "Delete course" link' do
        within_course_listing(course_1_1) { find('.test-course-del-link').click }
      end
      step 'Click on the "delete" button' do
        deletion_modal.click_button('Delete')
      end
      step 'I see the flash message "Course course_1_1 was deleted successfully."' do
        expect_flash('notice', 'Course course_1_1 was deleted successfully.')
      end
    end
  end

  scenario 'As an instructor with no course and section, I cannot see ' \
    'the focus widget on the Instructor dashboard' do
    create(:school_user, user: instructor, school: school_1)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    step 'Visit the dashboard home page' do
      visit instructor_dashboard_path(program.id)
    end
    step 'I cannot see the focus widget' do
      expect(page).not_to have_selector('#focus_indicator')
    end
  end

  scenario 'As an instructor I can see additional entries set by the program manager' do
    step 'Setup the database' do
      step 'Create instructor and set program configuration' do
        step 'Create additional menu entries' do
          # Make sure that program.vista_online_learning? will return `false`
          # so that the spec does not complain about missing learning tracks configuration.
          program.update(family: nil)

          ProgramConfig.create!(
            program_settings.merge(
              creator_id: create(:user).id,
              program_id: program.id
            )
          )
        end
        step 'Create instructor with access to the program' do
          create(:school_user, user: instructor, school: school_1)
          initialize_program_access_client_calls_for_instructor(instructor, program)
          log_in_as(instructor)
        end
      end
    end

    purpose 'I can see the additional entries' do
      step 'Visit the dashboard home page' do
        visit instructor_dashboard_path(program.id)
      end
      step 'I see the additional entry for students' do
        expect(page).to have_selector("a[href='#{program_settings[:content_menu_additional_entries][0][:url]}'][data-link-type='vtext']",
                                      text: program_settings[:content_menu_additional_entries][0][:label])
      end
      step 'I see the additional entry for instructors' do
        expect(page).to have_selector("a[href='#{program_settings[:content_menu_additional_entries][1][:url]}'][data-link-type='vtext']",
                                      text: program_settings[:content_menu_additional_entries][1][:label])
      end
    end
  end

  context 'When the instructor is from a RA school' do
    let(:instructor) { create(:one_roster_instructor) }
    let(:school) do
      create(:one_roster_school)
    end
    let(:course) do
      create(:course, school: school, owner: instructor, program: program)
    end
    let(:section) do
      create(:section, course: course, instructor: instructor)
    end
    let(:second_course) do
      create(:course, school: school, owner: instructor, program: program)
    end
    let(:second_section) do
      create(:section, course: second_course, instructor: instructor)
    end
    let(:one_roster_linked_section) do
      create(:one_roster_linked_section, section: second_section)
    end

    before do
      initialize_program_access_client_calls_for_instructor(instructor, program)
      create(:school_user, user: instructor, school: school)
      create(:one_roster_linked_user, user: instructor, school: school)
    end

    scenario 'When I do not have any courses, I am redirected to the course creation instructions' do
      log_in_as(instructor)

      purpose 'I am redirected to the Roster Assistant course creation instructions' do
        visit instructor_dashboard_path(program.id)
        expect(current_path).to eq add_one_roster_instructor_courses_path(program)
      end

      purpose 'I see the links to navigate the program content' do
        expect(page).to have_selector('.test-content-menu')
      end
    end

    scenario 'When I have an existing course and section, and it closed more than a month ago ' \
             'I see the course focus widget' do
      step 'Setup the database' do
        step 'Create instructor and set program configuration' do
          log_in_as(instructor)

          step 'Create course with section that ended 1 month and a day ago' do
            course_end_date = (1.month + 1.day).ago
            course_start_date = (course_end_date - 1.day)
            section.course.update!(
              start_date: course_start_date,
              end_date: course_end_date,
              allow_past_end_date: true
            )
          end
        end
      end

      purpose 'I see the course focus widget' do
        visit instructor_dashboard_path(program.id)
        expected_course_index_path = "/one_roster/#{program.id}/instructor/courses"
        expect(page).to have_selector('#focus_wrapper')
      end
    end

    scenario 'When I have an existing course and section, I do not see the add section link and the instructions for student is disabled' do
      step 'Setup the database' do
        step 'Create instructor and set program configuration' do
          log_in_as(instructor)

          step 'Create course with section' do
            section
          end
        end
      end

      purpose 'I do not see the add section link' do
        step 'go to the instructor dashboard' do
          visit instructor_dashboard_path(program.id)
        end
        purpose 'I cannot see the add section link' do
          expect(page).not_to have_selector("a[href='#{main_app.new_instructor_course_section_path(program, course)}']")
          expect(page).to have_selector(".test-section-#{section.id}")
        end
        purpose 'The instructions for students is disabled' do
          expect(page).to have_selector('.test-edit-section-asst-message', text: 'Instructions for Students')
        end
      end
    end

    scenario 'When there are two RA courses/sections, ' \
             'the delete section link works for the second section', js: true do
      step 'Setup the database' do
        step 'Create instructor and set program configuration' do
          log_in_as(instructor)

          step 'Create two courses with section' do
            section
            second_section
            one_roster_linked_section
          end
        end
      end

      deletion_modal = nil
      purpose 'I delete the second visible section of the dashboard' do
        step 'go to the instructor dashboard' do
          visit instructor_dashboard_path(program.id)
          find(".test-course-name-#{second_section.course_id}").click
        end
        step 'click on the "Delete section" link for the section' do
          expect(second_section).not_to be_archived
          within(".test-section-#{second_section.id}") do
            find('.test-gear').click
            find('.test-section-del-link').click
          end
        end
        step 'I see a modal asking if I am sure' do
          deletion_modal = find('.js-modal.js-section-del-modal')
          expect(deletion_modal).to have_content('Proceed with removing the ' \
                                                 'selected section and course?')
        end
        step 'Click on the "Confirm" button to delete the section' do
          deletion_modal = find('.js-modal.js-section-del-modal')
          deletion_modal.click_button('Confirm')

          second_section.reload
          one_roster_linked_section.reload

          expect(second_section).to be_archived
          expect(one_roster_linked_section.is_archived).to be_truthy
        end
      end
    end
  end

  context 'When program config manager hid menu content' do
    scenario 'As instructor,I cannot see hidden content menu' do
      step 'Setup the database' do
        step 'Create instructor and set program configuration' do
          step 'Create additional menu entries' do
            # Make sure that program.vista_online_learning? will return `false`
            # so that the spec does not complain about missing learning tracks configuration.
            program.update(family: nil)

            ProgramConfig.create!(
              program_settings_hide.merge(
                creator_id: create(:user).id,
                program_id: program.id
              )
            )
          end
          step 'Create instructor with access to the program' do
            create(:school_user, user: instructor, school: school_1)
            initialize_program_access_client_calls_for_instructor(instructor, program)
            log_in_as(instructor)
          end
        end
      end
      purpose 'I cannot see the hidden menu entries' do
        step 'go the show page for the section' do
          visit instructor_dashboard_path(program.id)
        end
        step 'I cannot see the activities menu entry' do
          expect(page).not_to have_selector("a[href='#{main_app.instructor_toc_path(program, @path_options)}']", text: 'Activities')
        end

        step 'I cannot see the my content menu entry' do
          expect(page).not_to have_selector("a[href='#{main_app.instructor_mycontent_path(program, @path_options)}']", text:  'My Content')
        end
      end
    end

    scenario 'As instructor, can see the menu entires' do

      step 'Setup the database' do
        step 'Create instructor and set program configuration' do
          step 'Create additional menu entries' do
            # Make sure that program.vista_online_learning? will return `false`
            # so that the spec does not complain about missing learning tracks configuration.
            program.update(family: nil)

            ProgramConfig.create!(
              program_settings.merge(
                creator_id: create(:user).id,
                program_id: program.id
              )
            )
          end
          step 'Create instructor with access to the program' do
            create(:school_user, user: instructor, school: school_1)
            initialize_program_access_client_calls_for_instructor(instructor, program)
            log_in_as(instructor)
          end
        end

      end
      purpose 'I can see the complete menu entries' do
        step 'go the show page for the section' do
          visit instructor_dashboard_path(program.id)
        end
        step 'I can see the activities menu entry' do
          expect(page).to have_selector("a[href='#{main_app.instructor_toc_path(program, @path_options)}']", text: 'Activities')
        end

        step 'I can see the my content menu entry' do
          expect(page).to have_selector("a[href='#{main_app.instructor_mycontent_path(program, @path_options)}']", text: 'My Content')
        end
      end
    end
  end

  scenario 'Large roster hides section and category averages' do
    step 'Setup the database' do
      create(:school_user, user: instructor, school: school_1)
      initialize_program_access_client_calls_for_instructor(instructor, program)
      course = create(:course, school: school_1, owner: instructor, program:)
      section = create(:section, course:, instructor:)
      (Instructor::DashboardHelper::SECTION_AVERAGE_STUDENT_THRESHOLD + 1).times { create(:enrollment, section:) }
      create(:category, course:)
      create(:category, course:)

      log_in_as(instructor)
      visit instructor_dashboard_path(program.id)

      purpose 'Summary shows student count link; averages are hidden' do
        expected_roster_href = "/#{program.id}/sections/#{section.id}/roster"
        step 'Student count link shows 51 and is clickable' do
          expected_count = Instructor::DashboardHelper::SECTION_AVERAGE_STUDENT_THRESHOLD + 1
          expect(page).to have_link(expected_count.to_s, href: expected_roster_href)
        end
        step 'Section average placeholder and spinner are not present' do
          expect(page).to have_no_css(
            ".test-section-#{section.id}-average"
          )
          expect(page).to have_no_css(
            ".js-section-average-pulser-#{section.id}"
          )
        end
      end

      purpose 'Detail view shows Gradebook labels; no category averages' do
        step 'Expand the section' do
          find(".js-section-name[data-section-id='#{section.id}']").click
        end
        step 'Labels switch to Gradebook and roster link remains' do
          within(".js-section_#{section.id}-wrapper") do
            expect(page).to have_css(
              '.c-section-detail__item-button--mobile',
              text: 'Gradebook'
            )
            expect(page).to have_css(
              '.c-button.c-section-detail__item-button',
              text: 'Gradebook'
            )
            expected_count = Instructor::DashboardHelper::SECTION_AVERAGE_STUDENT_THRESHOLD + 1
            expected_roster_href = "/#{program.id}/sections/#{section.id}/roster"
            expect(page).to have_link(expected_count.to_s, href: expected_roster_href)
          end
        end
        step 'Category-average placeholders are not present' do
          expect(page).to have_no_css(
            "[class*='test-section-#{section.id}-category-'][class*='-average']"
          )
        end
      end
    end
  end

  scenario 'Roster with 50 or less students shows section and category average placeholders' do
    step 'Setup the database' do
      create(:school_user, user: instructor, school: school_1)
      initialize_program_access_client_calls_for_instructor(instructor, program)
      course = create(:course, school: school_1, owner: instructor, program:)
      section = create(:section, course:, instructor:)
      Instructor::DashboardHelper::SECTION_AVERAGE_STUDENT_THRESHOLD.times { create(:enrollment, section:) }
      cat_1 = create(:category, course:)
      cat_2 = create(:category, course:)

      log_in_as(instructor)
      visit instructor_dashboard_path(program.id)

      purpose 'Summary shows student count and section average placeholder' do
        expected_roster_href = "/#{program.id}/sections/#{section.id}/roster"
        step 'Student count link shows 50 and is clickable' do
          expected_count = Instructor::DashboardHelper::SECTION_AVERAGE_STUDENT_THRESHOLD
          expect(page).to have_link(expected_count.to_s, href: expected_roster_href)
        end
        step 'Section average placeholder is present' do
          expect(page).to have_css(
            ".test-section-#{section.id}-average"
          )
        end
      end

      purpose 'Detail view shows Section average labels and category placeholders' do
        step 'Expand the section' do
          find(".js-section-name[data-section-id='#{section.id}']").click
        end
        step 'Labels show Section average and roster link remains' do
          within(".js-section_#{section.id}-wrapper") do
            expect(page).to have_css(
              '.c-section-detail__item-button--mobile',
              text: 'Section average'
            )
            expect(page).to have_css(
              '.c-button.c-section-detail__item-button',
              text: 'Section average'
            )
            expected_count = Instructor::DashboardHelper::SECTION_AVERAGE_STUDENT_THRESHOLD
            expected_roster_href = "/#{program.id}/sections/#{section.id}/roster"
            expect(page).to have_link(expected_count.to_s, href: expected_roster_href)
          end
        end
        step 'Category-average placeholders are present' do
          expect(page).to have_css(
            ".test-section-#{section.id}-category-#{cat_1.id}-average"
          )
          expect(page).to have_css(
            ".test-section-#{section.id}-category-#{cat_2.id}-average"
          )
        end
      end
    end
  end
end
