feature 'Course library', test_debt: true, chrome: true, js: true do
  include RspecJsApiHelpers
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include Capybara::Angular::DSL

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, language_code: 'de', family: 'vista_online_learning') }
  let(:student) { create(:student) }
  let!(:activity) { create_activity_with_unit_lesson_and_concept(program) }
  let(:course_licenses) { Array.new }

  let(:course_package) do
    Maestro::CoursePackage.new(
      'content_type' => 'level',
      'id' => 1,
      'name' => 'Supersite'
    )
  end

  def a_section_with_course_exists_for(instructor, program)
    course = create(
      :course,
      owner: instructor,
      program: program,
      first_unit: program.units.first,
      last_unit: program.units.last
    )
    @course_packages_by_course[course.guid] = [course_package]

    create(:section, course: course, instructor: instructor)
  end

  before do
    create(:vol_program_config, program: program)

    allow(Maestro::LicenseGroup).to receive(:all)
      .and_return([double('LicenseGroup', id: 1, name: '01-Supersite')])
    course_licenses << Maestro::CourseLicense.new('license_group' => { 'id' => 1, 'demo' => false })

    allow(Maestro::CoursePackage).to receive(:all).and_return([])
    allow(Maestro::CoursePackage).to receive(:available_packages)
      .and_return([course_package])

    @course_packages_by_course = {}
    allow(Maestro::CoursePackage).to receive(:all_for_courses)
      .and_return(@course_packages_by_course)

    allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)
    allow(Maestro::UserLicense).to receive(:all_for_user_and_program).with([], program.id).and_return([])
    activity.update!(license_group_id: course_licenses.first.license_group.id)
    @recycle_bin = []
  end

  after(:each) do
    page.execute_script('localStorage.clear();')
    # clear localStorage to prevent any inter-test interactions
    page.execute_script('sessionStorage.clear();')
  end

  after do
    @recycle_bin.each do |file|
      if File.exist?(file)
        if File.directory?(file)
          FileUtils.remove_dir(file)
        else
          File.unlink(file)
        end
      end
    end
  end

  describe 'as an instructor' do
    before do
      initialize_program_access_client_calls_for_instructor(instructor, program)
      log_in_as(instructor)
    end

    scenario 'Instructor can add an activity back to the course library' do
      section = a_section_with_course_exists_for(instructor, program)
      CourseLibraryActivity.hide_activity(activity.id, section.course_id)
      visit instructor_toc_path(program)
      expect(page).to have_selector("#due_date_cell_for_activity_id_#{activity.id}", text: 'hidden', visible: true)
      first("#activity_#{activity.id}_checkbox").click
      sleep 1
      first("a[data-activity-id='#{activity.id}']", text: 'Show').click
      sleep 1
      expect(page).to have_selector("#due_date_cell_for_activity_id_#{activity.id}", text: '', visible: true)
      @recycle_bin << activity.content_filepath
    end

    scenario 'Instructor can remove an unassigned activity from a course' do
      section = a_section_with_course_exists_for(instructor, program)
      visit instructor_toc_path(program)
      expect(page).to have_selector("#due_date_cell_for_activity_id_#{activity.id}", text: '', visible: true)
      first("#activity_#{activity.id}_checkbox").click
      sleep 1
      first("a[data-activity-id='#{activity.id}']", text: 'Hide').click
      sleep 1
      expect(page).to have_selector("#due_date_cell_for_activity_id_#{activity.id}", text: 'hidden', visible: true)
      @recycle_bin << activity.content_filepath
    end

    scenario 'Instructor can create a course and get the default VHL activities' do
      create(:unit_with_lesson_with_toc_entries, program: program)
      allow(Maestro::CourseLicense).to receive(:create)
      allow(Maestro::School).to receive(:instructors).and_return([])
      section = a_section_with_course_exists_for(instructor, program)
      instructor.schools << section.school
      # here we change the course library settings for the existing course
      CourseLibraryActivity.hide_activity(activity.id, section.course_id)
      visit instructor_new_course_path(program, section.school)
      # Select advanced setup
      click_on('select advanced setup')
      puts page.current_url # Use expect_url
      # set the course name
      find('input[name="course_name"]').set('Course Library Course')
      # Click the Next button
      find('.next').click
      puts page.current_url # Use expect_url
      # Copy content settings from 'Basic Course'
      select('Basic course', from: 'previous_course_id')
      puts page.current_url # Use expect_url
      find('.next').click
      puts page.current_url # Use expect_url
      #first('.red-button', text: 'Next').click
      #sleep 1
      # Copy category settings from 'Basic Course'
      select('Basic course', from: 'previous_course_id')
      first('.red-button', text: 'Next').click
      # TODO: check that we are on the summary page?
      first('.red-button', text: 'Save').click
      # The save button triggered a confirmation modal window
      within(find('div.ui-dialog')) do
        # confirm by clicking 'yes'
        click('.test-confirm-yes')
      end
      # Fill in the section name
      fill_in('section_name', with: 'Section 1')
      first('.red-button', text: 'Next').click
      # Select the days your section meets: select monday
      first('[data-js-day-name="Monday"]').set(true)
      # Save section
      first('.red-button[value="Save section"]').click
      # O popup with 'Do you want to create another section' appears
      within(find('div.ui-dialog')) do
        # Select 'no'
        click('.test-confirm-no')
      end



      # ADAM: best class to use?
      # .red-button and text
      # data-js-button="category_geT_started"
      find('data-js-button="category_get_started"').click
# click add category? or copy category settings from 'basuic course'
      first('.red-button', text: 'Save').click
      sleep 2
      first('.red-button', text: 'Yes').click
      sleep 3
      fill_in('section_name', with: 'Section 1')
      sleep 1
      first('.red-button', text: 'Next').click
      sleep 1
      first('[data-js-day-name="Monday"]').set(true)
      sleep 1
      first('.red-button[value="Save section"]').click
      sleep 1
      first('#ui-id-1 .white-button', text: 'No').click
      sleep 1
      #debugger
      #take_screenshot
      #dump_the_page
      #first('#ui-id-3 .white-button', text: 'No').click
      #sleep 3
      #first("a#js_course_#{Course.last.id}").click
      #sleep 1
      visit instructor_toc_path(program)
      # here we test that the course preference from the other course were not migrated to the new course
      expect(page).to have_selector("#due_date_cell_for_activity_id_#{activity.id}", text: '', visible: true)
      sleep 1
      @recycle_bin << activity.content_filepath
    end

    describe 'As an instructor, I can only make changes to visibility or add content when focused on a course' do
      before do
        give_instructor_access_to_toc
        @section = a_section_with_course_exists_for(instructor, program)
        @course = @section.course
        @another_section = create(:section, course: @course, instructor: instructor)
      end

      context 'content activities have visibility conditions' do
        before do
          visit instructor_toc_path(program)
        end

        scenario 'when there are multiple sections' do
          first("#focus_indicator").click
          first("#js_section_#{@section.id}").click
          sleep 1
          expect(page).not_to have_selector('[data-content-type="add_custom_activity_control"]')

          first("#activity_#{activity.id}_checkbox").click
          sleep 1
          expect(page).not_to have_selector("a[data-activity-id='#{activity.id}']")

          first("#focus_indicator").click
          first("#js_course_#{@course.id}").click
          sleep 1
          expect(page).to have_selector('[data-content-type="add_custom_activity_control"]')

          first("#activity_#{activity.id}_checkbox").click
          sleep 1
          expect(page).to have_selector("a[data-activity-id='#{activity.id}']")
        end

        scenario 'when the course only have one section' do
          @course.sections.last.destroy
          first("#focus_indicator").click
          first("#js_section_#{@section.id}").click
          sleep 1
          expect(page).to have_selector('[data-content-type="add_custom_activity_control"]')

          first("#activity_#{activity.id}_checkbox").click
          sleep 1
          expect(page).to have_selector("a[data-activity-id='#{activity.id}']")
        end
      end # end-of content activities context

      context 'content assessments have visibility conditions' do
        before do
          program.lessons.each do |lesson|
            lesson.toc_entries.each{ |toc_entry| toc_entry.assessment = true }
            lesson.save!
          end
          visit instructor_assessments_path(program)
        end

        scenario 'when the course only have one section, I do not see the IGC controls' do
          first("#focus_indicator").click
          first("#js_section_#{@section.id}").click
          sleep 1
          expect(page).not_to have_selector('[data-content-type="add_custom_activity_control"]')

          first("#activity_#{activity.id}_checkbox").click
          sleep 1

          expect(page).not_to have_selector("a[data-activity-id='#{activity.id}']")
        end
      end # end-of content assessments context
    end
  end

  describe 'as a student' do
    before do
      initialize_program_access_client_calls_for_user_and_program(student, program)
      give_user_access_to_program(student, program)
      log_in_as(student)
    end

    scenario 'Student not in a course cannot see instructor created activities' do
      instructor_created_activity = activity.dup
      instructor_created_activity.title = activity.title + '_instructor_copy'
      instructor_created_activity.instructor_revision_id = 1
      instructor_created_activity.save!
      visit section_toc_path(0, program)
      expect(page).to have_text activity.title
      expect(page).not_to have_text instructor_created_activity.title

      @recycle_bin << activity.content_filepath
      @recycle_bin << instructor_created_activity.content_filepath
    end
  end


end
