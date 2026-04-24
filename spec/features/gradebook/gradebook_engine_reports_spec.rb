feature 'Reports',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include RspecJsDownloadHelpers
  include GradebookEngineHelpers
  include CapybaraViewHelpers
  include WaitForNextPage

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program
    )
  end

  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:section_2) { create(:section, course: course, instructor: instructor) }

  let(:activity) do
    create_activity_with_unit_lesson_and_concept(program, points_possible: 10)
  end

  let(:category_1) do
    create(
      :category,
      accept_late_work: true,
      course: course,
      credit_only: false,
      late_work_penalty: 'none',
      weighting_percent: 50
    )
  end

  let(:category_2) do
    create(
      :category,
      course: course,
      credit_only: false,
      weighting_percent: 50
    )
  end

  let(:reports_index_url) do
    gradebook_engine.course_reports_path(
      course_id: course.id, program_id: program.id, section_id: section.id
    )
  end

  let(:from_date_radio_id) { 'report_from_specific_date_true' }
  let(:to_date_radio_id) { 'report_to_specific_date_true' }

  let(:name_selector) { '.test-report_name' }
  let(:range_selector) { '.test-summary_range' }
  let(:category_name_selector) { '.test-summary_category_name' }

  let(:activity_for_first_day) do
    create_activity_with_unit_lesson_and_concept(
      program,
      lesson: activity.lesson,
      points_possible: 10
    )
  end

  let(:activity_for_yesterday) do
    create_activity_with_unit_lesson_and_concept(
      program,
      lesson: activity.lesson,
      points_possible: 10
    )
  end

  let(:day_after_start_date) do
    mm_dd_yyyy(course.start_date + 1.day)
  end

  let(:day_before_yesterday) do
    mm_dd_yyyy(Date.today - 2.days)
  end

  let(:denied_error) { GradebookEngine::ReportsController::ACCESS_DENIED_ERROR }

  def expect_access_to_be_denied(include_section_id: true)
    url_params = {
      course_id: course.id,
      program_id: program.id
    }.tap do |memo|
      memo[:section_id] = section.id if include_section_id
    end
    expect_url(gradebook_engine.course_reports_path(url_params))
    expect_flash_message(:error, denied_error)
  end

  def mm_dd_yyyy(date)
    date.strftime('%m-%d-%Y')
  end

  def report_row(report)
    "tr.test-report#{report.id}"
  end

  def click_edit_report_link
    click_link(exact_text: 'Edit')
  end

  before do
    create(:enrollment, user: student_1, section: section)
    create(:enrollment, user: student_2, section: section_2)
    initialize_program_access_client_calls_for_instructor(instructor, program)
  end

  # I have to deviate from the recommended practice of not nesting scenarios
  # within context/describe blocks in order to be able to use "let" to set
  # different programs.
  describe 'in programs with lessons but not units' do
    let(:program) { create(:program_with_toc_entries) }
    before { log_in_as(instructor) }

    scenario 'As an instructor, I can manage reports in a single-tier program',
             downloads: true, retry: 2 do
      # Go to the top-level gradebook page
      wait_for_next_page do
        visit gradebook_engine.course_section_scores_path(
          course_id: course.id, program_id: program.id, section_id: section.id
        )
      end

      # Expect to see a link for Reports
      find('.c-subnav__link', text: 'Reports').click

      # From the reports index page, there should be a link to create a report
      click_link('Create New Report')

      # Before assigning anything, verify that running report with no
      # assignments doesn't throw an error.

      # Choosing to break out by Week throws an error without code in
      # place to guard against it.
      vhl_choose('Week', allow_label_click: true)

      click_button('Run Report')

      expect(page).to have_selector('.test-no_assignments_warning')
      expect(page).to have_selector('button.is-disabled', text: 'Export')

      # Assign and add a submission for activity in first lesson.
      create(
        :assignment,
        assignable: activity,
        category: category_1,
        due_date: 2.days.ago,
        section: section
      )
      create_gradebook_engine_submission(
        activity: activity,
        pending: false,
        points_earned: 2.0,
        section: section,
        submitted_at: 3.days.ago.to_date,
        student: student_1,
        time_spent: 3_600
      )

      # Create an activity the student didn't submit
      unsubmitted_activity = create_activity_with_unit_lesson_and_concept(
        program,
        lesson: activity.lesson,
        points_possible: 5,
        strand_id: activity.lesson.strands.first.location
      )
      create(
        :assignment,
        assignable: unsubmitted_activity,
        category: category_1,
        due_date: 2.days.ago,
        section: section
      )

      # Create an activity in another lesson, assign and add a submission.
      lesson_2 = program.units[1].lessons.first
      lesson_2_activity = create_activity_with_unit_lesson_and_concept(
        program,
        lesson: lesson_2,
        points_possible: 10,
        strand_id: lesson_2.strands.first.location
      )
      create(
        :assignment,
        assignable: lesson_2_activity,
        category: category_1,
        due_date: 2.days.ago,
        section: section
      )
      create_gradebook_engine_submission(
        activity: lesson_2_activity,
        pending: false,
        points_earned: 3.0,
        section: section,
        submitted_at: 3.days.ago.to_date,
        student: student_1,
        time_spent: 91 # To test rounding up to nearest minute
      )

      # Create a submitted activity assigned in a different category
      category_2_activity = create_activity_with_unit_lesson_and_concept(
        program,
        lesson: activity.lesson,
        points_possible: 10,
        strand_id: activity.lesson.strands.first.location
      )
      create(
        :assignment,
        assignable: category_2_activity,
        category: category_2,
        due_date: 2.days.ago,
        section: section
      )
      create_gradebook_engine_submission(
        activity: category_2_activity,
        pending: false,
        points_earned: 7.0,
        section: section,
        submitted_at: 3.days.ago.to_date,
        student: student_1,
        time_spent: 60
      )

      # For date range:
      #
      # Create assignment due on first day of course
      #   and submit it.
      create(
        :assignment,
        assignable: activity_for_first_day,
        category: category_1,
        due_date: course.start_date,
        section: section
      )
      create_gradebook_engine_submission(
        activity: activity_for_first_day,
        pending: false,
        points_earned: 2.0,
        section: section,
        submitted_at: 3.days.ago.to_date,
        student: student_1,
        time_spent: 3_600
      )

      # Create assignment due yesterday.
      #   Note that specific "to" date will need to be two days ago
      #   to show that this assignment is excluded.
      create(
        :assignment,
        assignable: activity_for_yesterday,
        category: category_1,
        due_date: Date.today - 1.day,
        section: section
      )
      create_gradebook_engine_submission(
        activity: activity_for_yesterday,
        pending: false,
        points_earned: 2.0,
        section: section,
        submitted_at: 3.days.ago.to_date,
        student: student_1,
        time_spent: 3_600
      )

      lessons = section.lessons_covered

      # Verify default initial values
      wait_for_next_page do
        visit gradebook_engine.new_course_report_path(
          course_id: course.id, program_id: program.id, section_id: section.id
        )
      end

      # For lesson range, the first and last lessons of the course should be
      # selected by default
      expect(find('#report_first_lesson_id').value).to eq(lessons.first.id.to_s)
      expect(find('#report_last_lesson_id').value).to eq(lessons.last.id.to_s)

      # For category, the "All" radio button should be checked by default
      expect(page).to have_checked_field('All')

      # For level, the "Cumulative" radio button should be checked by default
      expect(page).to have_checked_field('Cumulative')

      # There should be no "Unit" radio button for level, as this is a
      # single-tier program.
      expect(page).to have_no_field('Unit')

      # For data columns, the "Percentage" checkbox should be checked by default
      expect(page).to have_checked_field('Percentage')

      # Select the lesson range

      # Verify that all options show up in edit form. Incorrect config of
      # the rails select helper could result in first lesson not showing.
      options = selectbox_options(:report_first_lesson_id)
      option_ids = options.map { |option| option['value'].to_i }

      expect(options.map(&:text)).to eq(lessons.map(&:name))
      close_selectbox_menu(:report_first_lesson_id)

      # Trying to run the report with the end lesson set to a lesson before the
      # start lesson should fail and show validation messages
      choose_from_selectbox(:report_first_lesson_id, lessons.last.name)
      choose_from_selectbox(:report_last_lesson_id, lessons.first.name)
      click_button('Run Report')

      expect_flash_message(:error, 'Failed to run report')

      # Expect the invalid choices to still be shown as selected in the
      # lessons dropdowns.
      expect(find('#report_first_lesson_id').value).to eq(lessons.last.id.to_s)
      expect(find('#report_last_lesson_id').value).to eq(lessons.first.id.to_s)

      # Set valid Lesson options
      choose_from_selectbox(:report_first_lesson_id, lessons.first.name)
      choose_from_selectbox(:report_last_lesson_id, lessons.last.name)

      # Select Date Range
      # Expect start date default to be "start of course"
      expect(page).to have_checked_field('Start of Course')
      expect(page).to have_unchecked_field(from_date_radio_id)

      # Expect end date default to be "today"
      expect(page).to have_checked_field('Yesterday')
      expect(page).to have_unchecked_field(to_date_radio_id)

      # Change start date to be after the end date (or swap them)
      vhl_choose(from_date_radio_id, allow_label_click: true)
      fill_in('Specific From Date', with: mm_dd_yyyy(course.end_date))

      vhl_choose(to_date_radio_id, allow_label_click: true)
      fill_in('Specific To Date', with: mm_dd_yyyy(course.start_date))

      # Run Report & Expect error
      click_button('Run Report')
      expect_flash_message(:error, 'Failed to run report')

      # Select default values
      vhl_choose('Start of Course', allow_label_click: true)
      vhl_choose('Yesterday', allow_label_click: true)

      # Radio button for All Categories should be checked by default, the
      # other categories should be unchecked.
      expect(page).to have_checked_field('All')
      expect(page).to have_unchecked_field(category_1.name)
      expect(page).to have_unchecked_field(category_2.name)

      # Trying to run the report without any datafields selected should fail
      # and show validation messages
      vhl_uncheck('Percentage', allow_label_click: true)
      click_button('Run Report')

      expect_flash_message(:error, 'Failed to run report')

      vhl_check('Percentage', allow_label_click: true)
      vhl_check('Points Earned', allow_label_click: true)
      vhl_check('Points Possible', allow_label_click: true)
      vhl_check('Time Spent', allow_label_click: true)
      vhl_check('Activities Assigned', allow_label_click: true)
      vhl_check('Activities Completed', allow_label_click: true)

      # After choosing options, there should be a button for running the report.
      click_button('Run Report')

      # When viewing the report that has been run,

      # The lesson range in the summary header should be Lesson 1 - Lesson 3
      expect(find(range_selector).text).to include("#{lessons.first.name} - #{lessons.last.name}")

      # The date range in the summary header should be Start of Course - Yesterday
      expect(find(range_selector).text).to include('Start of Course - Yesterday')

      # The category name in the summary header should be All
      expect(find(category_name_selector)).to have_text('All')

      # I should see a row for the student
      student_row = find("tr.test-student#{student_1.id}")

      # TODO: Expect no assignments outside that range of due dates

      # I should see the student's grade as 45%
      # Category 1 (50%):
      # 6 / 35 points from lesson 1, 3 / 10 points from lesson 2.
      # 9 / 45 points total
      # Category 2 (50%):
      # 7 / 10 points
      # Combined: 0.5 * 20% + 0.5 * 70%: 45%, 16 out of 55 points
      # Time spent: 10800 + 91 + 60 sec is 3 hr, 2 min, and 31 sec which should
      # get rounded up to 3 hr 3 min
      expect(student_row).to have_selector('td.test-percent', text: '45.0%')
      expect(student_row).to have_selector('td.test-points_earned', exact_text: '16.0')
      expect(student_row).to have_selector('td.test-points_possible', exact_text: '55.0')
      expect(student_row).to have_selector('td.test-time_spent', exact_text: '03h 03m')
      expect(student_row).to have_selector('td.test-completed_count', text: '5')
      expect(student_row).to have_selector('td.test-assigned_count', text: '6')

      enable_headless_downloads do
        click_button('Export')

        csv_content = last_download_content(encoding: 'windows-1252:utf-8')
        rows = CSV.parse(csv_content)
        expect(rows[2]).to eq([student_1.last_name, student_1.first_name,
                               '45.0%', '16.0', '55.0', '03h 03m', '5', '6'])
      end

      # Change the level
      click_edit_report_link

      vhl_choose('Lesson', allow_label_click: true)

      click_button('Run Report')

      # TODO: Add test classes to make it easier to check stuff.

      # Change the level again
      click_edit_report_link

      # TODO: Do data setup in multiple weeks, add test classes to make it
      # easier to check stuff.

      vhl_choose('Week', allow_label_click: true)

      click_button('Run Report')

      # Change the level again
      click_edit_report_link

      vhl_choose('report_level_category', allow_label_click: true)

      click_button('Run Report')

      # Change the level one last time to activity
      click_edit_report_link
      vhl_choose('Activity', allow_label_click: true)

      # Activity data should be disabled and unchecked
      expect(page).to have_field('Activities Completed', disabled: true, checked: false)
      expect(page).to have_field('Activities Assigned', disabled: true, checked: false)

      click_button('Run Report')

      # I should see the grade data
      student_row = find("tr.test-student#{student_1.id}")
      expect(student_row).to have_selector("td.test-activity#{activity.id}_percent", text: '20.0%')
      expect(student_row).to have_selector("td.test-activity#{activity.id}_points_earned", exact_text: '2.0')
      expect(student_row).to have_selector("td.test-activity#{activity.id}_points_possible", exact_text: '10.0')
      expect(student_row).to have_selector("td.test-time_spent", exact_text: '01h 00m')
      expect(student_row).to have_selector("td.test-activity#{unsubmitted_activity.id}_points_earned", exact_text: '0.0')
      expect(student_row).to have_selector("td.test-activity#{category_2_activity.id}_points_earned", exact_text: '7.0')
      expect(student_row).to have_selector("td.test-activity#{lesson_2_activity.id}_points_earned", exact_text: '3.0')
      expect(student_row).to have_selector("td.test-activity#{activity_for_first_day.id}_points_earned", exact_text: '2.0')
      expect(student_row).to have_selector("td.test-activity#{activity_for_yesterday.id}_points_earned", exact_text: '2.0')
      expect(student_row).not_to have_selector('td.test-completed_count')
      expect(student_row).not_to have_selector('td.test-assigned_count')


      # Lets change the categories before saving
      click_edit_report_link

      # Switch back to cumulative
      vhl_choose('Cumulative', allow_label_click: true)

      # Re-check activity data
      vhl_check('Activities Assigned', allow_label_click: true)
      vhl_check('Activities Completed', allow_label_click: true)

      # My previously selected values should still be selected
      expect(page).to have_checked_field('Percentage')
      expect(page).to have_checked_field('Points Earned')
      expect(page).to have_checked_field('Points Possible')
      expect(page).to have_checked_field('Time Spent')
      expect(page).to have_checked_field('Activities Completed')
      expect(page).to have_checked_field('Activities Assigned')

      # Choose a new category
      vhl_choose(category_1.name, allow_label_click: true)

      click_button('Run Report')

      # I should see the name of the category I selected
      expect(find(category_name_selector)).to have_text(category_1.name)

      # I should see the grade data without assignments from category 2
      student_row = find("tr.test-student#{student_1.id}")
      expect(student_row).to have_selector('td.test-percent', text: '20.0%')
      expect(student_row).to have_selector('td.test-points_earned', exact_text: '9.0')
      expect(student_row).to have_selector('td.test-points_possible', exact_text: '45.0')
      expect(student_row).to have_selector('td.test-time_spent', exact_text: '03h 02m')
      expect(student_row).to have_selector('td.test-completed_count', text: '4')
      expect(student_row).to have_selector('td.test-assigned_count', text: '5')

      # The report should display as Unsaved
      expect(find(name_selector)).to have_text('Unsaved Report')

      # I click Save Template to bring up the Save modal
      click_link('Save Template')

      report_name = 'My first report'

      # Within the modal I set the name and save
      fill_in('Name this report', with: report_name)

      click_button('Save')

      # I'm still on the report page but now it's saved.
      expect_flash_message(:notice, "Successfully saved settings as #{report_name}")
      expect(find(name_selector)).to have_text(report_name)

      report = GradebookEngine::Report.last

      # I should see the same grade data
      student_row = find("tr.test-student#{student_1.id}")
      expect(student_row).to have_selector('td.test-percent', text: '20.0%')
      expect(student_row).to have_selector('td.test-points_earned', exact_text: '9.0')
      expect(student_row).to have_selector('td.test-points_possible', exact_text: '45.0')
      expect(student_row).to have_selector('td.test-time_spent', exact_text: '03h 02m')
      expect(student_row).to have_selector('td.test-completed_count', text: '4')
      expect(student_row).to have_selector('td.test-assigned_count', text: '5')

      # Create a report in another program, and one owned by another instructor
      # Which shouldn't be shown on the index page.
      GradebookEngine::Report.create!(
        data_columns: ['percentage'],
        first_lesson_id: activity.lesson.id,
        last_lesson_id: activity.lesson.id,
        level: 'Cumulative',
        name: 'other program report',
        owner_id: instructor.id,
        program_id: create(:program).id
      )

      GradebookEngine::Report.create!(
        data_columns: ['percentage'],
        first_lesson_id: activity.lesson.id,
        last_lesson_id: activity.lesson.id,
        level: 'Cumulative',
        name: 'other instructor report',
        owner_id: create(:instructor).id,
        program_id: program.id
      )

      # Go to the reports index page
      find('a', text: 'Return to Reports Home').click

      # I should see only the newly saved report for the current program
      # and instructor listed.
      expect(all(name_selector).size).to eq(1)
      expect(
        find("#{report_row(report)} #{name_selector}")
      ).to have_text(report_name)

      # Click the Edit link for the report
      within(report_row(report)) { click_link('Edit') }

      # My previously selected values should still be selected
      expect(page).to have_checked_field('Percentage')
      expect(page).to have_checked_field('Points Earned')
      expect(page).to have_checked_field('Points Possible')
      expect(page).to have_checked_field('Time Spent')
      expect(page).to have_checked_field('Activities Completed')
      expect(page).to have_checked_field('Activities Assigned')

      click_button('Run Report')

      new_report_name = 'My edited report'

      # I click Save Template to bring up the Save modal
      click_link('Save Template')

      # I fill in the name field with the new report name
      fill_in('Name this report', with: new_report_name)

      click_button('Save')

      # I'm still on the report page but now it shows the new name
      expect_flash_message(:notice, "Successfully saved settings as #{new_report_name}")
      expect(find(name_selector)).to have_text(new_report_name)

      # I didn't lose any of my settings.
      student_row = find("tr.test-student#{student_1.id}")
      expect(student_row).to have_selector('td.test-percent', text: '20.0%')
      expect(student_row).to have_selector('td.test-points_earned', exact_text: '9.0')
      expect(student_row).to have_selector('td.test-points_possible', exact_text: '45.0')
      expect(student_row).to have_selector('td.test-time_spent', exact_text: '03h 02m')
      expect(student_row).to have_selector('td.test-completed_count', text: '4')
      expect(student_row).to have_selector('td.test-assigned_count', text: '5')

      # Change the lesson range.
      click_edit_report_link

      # Set both start and end lessons to lesson 1
      choose_from_selectbox(:report_first_lesson_id, lessons.first.name)
      choose_from_selectbox(:report_last_lesson_id, lessons.first.name)
      click_button('Run Report')

      # I should see the student's grade as 17.1%
      # 6 / 15 points from lesson 1, no points from lesson 2
      # 6 / 15 points total.
      # Time spent: 10800 sec in lesson 1: 3 hour
      student_row = find("tr.test-student#{student_1.id}")
      expect(student_row).to have_selector('td.test-percent', text: '17.1%')
      expect(student_row).to have_selector('td.test-points_earned', exact_text: '6.0')
      expect(student_row).to have_selector('td.test-points_possible', exact_text: '35.0')
      expect(student_row).to have_selector('td.test-time_spent', exact_text: '03h 00m')
      expect(student_row).to have_selector('td.test-completed_count', text: '3')
      expect(student_row).to have_selector('td.test-assigned_count', text: '4')

      # Change the Date Range to non-default
      click_edit_report_link

      # Select new, valid start date
      vhl_choose(from_date_radio_id, allow_label_click: true)

      fill_in('Specific From Date', with: day_after_start_date)
      # TODO: Add text box with from date & datepicker

      # Select new end date before yesterday
      vhl_choose(to_date_radio_id, allow_label_click: true)
      fill_in('Specific To Date', with: day_before_yesterday)
      # TODO: Add text box with to date & date picker

      click_button('Run Report')

      # The lesson range in the summary header should be Lesson 1 - Lesson 1
      expect(find(range_selector).text).to include(
        "#{lessons.first.name} - #{lessons.first.name}"
      )

      # The date range in the summary header should be
      #   [day after start of course] - [day before yesterday]
      expect(find(range_selector).text).to include(
        "#{day_after_start_date} - #{day_before_yesterday}"
      )

      # Only two activities meet the report criteria: activity and unsubmitted_activity.

      # Go back to the reports index page
      click_link('Return to Reports Home')

      # Expect to see the new name
      expect(
        find("#{report_row(report)} #{name_selector}")
      ).to have_text(new_report_name)

      # Change the category

      # Click the Edit link for the report
      within(report_row(report)) { click_link('Edit') }

      # Set the lesson range back to all lessons
      choose_from_selectbox(:report_first_lesson_id, lessons.first.name)
      choose_from_selectbox(:report_last_lesson_id, lessons.last.name)

      # Choose a new category
      vhl_choose(category_2.name, allow_label_click: true)

      click_button('Run Report')

      # Expect to see the new category name in the summary
      expect(find(category_name_selector)).to have_text(category_2.name)

      click_link('Save Template')
      click_button('Save')

      # Go back to the reports index page
      click_link('Return to Reports Home')

      # Expect to see the new category name in the summary
      expect(
        find("#{report_row(report)} .test-category_name")
      ).to have_text(category_2.name)

      # Click the Edit link for the report
      within(report_row(report)) { click_link('Edit') }

      vhl_choose(category_1.name, allow_label_click: true)

      click_button('Run Report')
      click_link('Save Template')
      click_button('Save')

      click_edit_report_link

      # Uncheck all data columns
      vhl_uncheck('Percentage', allow_label_click: true)
      vhl_uncheck('Points Earned', allow_label_click: true)
      vhl_uncheck('Points Possible', allow_label_click: true)
      vhl_uncheck('Time Spent', allow_label_click: true)
      vhl_uncheck('Activities Completed', allow_label_click: true)
      vhl_uncheck('Activities Assigned', allow_label_click: true)
      click_button('Run Report')

      # Expect an error message because at least one column is required.
      expect_flash_message(:error, 'Failed to run report')

      # Go back to the reports index page
      find('a', text: 'Return to Reports Home').click

      # Expect to see the new name
      expect(
        find("#{report_row(report)} #{name_selector}")
      ).to have_text(new_report_name)

      # Create a submission in a different section
      create(
        :assignment,
        assignable: activity,
        category: category_1,
        due_date: 2.days.ago,
        section: section_2
      )
      create_gradebook_engine_submission(
        activity: activity,
        pending: false,
        points_earned: 5.0,
        section: section_2,
        submitted_at: 3.days.ago.to_date,
        student: student_2,
        time_spent: 3_900
      )

      # Change the focus to the other section
      wait_for_next_page do
        visit(
          gradebook_engine.course_reports_path(
            course_id: course.id, program_id: program.id, section_id: section_2.id
          )
        )
      end

      # Click the new report to run it
      click_link(new_report_name)

      # should see section 2 data instead of section 1 data

      # I should see the student's grade as 50.0%
      # 5 / 10 points from lesson 1
      # Time spent: 3900 sec in lesson 1: 1 hour 5 mins
      student_row = find("tr.test-student#{student_2.id}")
      expect(student_row).to have_selector('td.test-percent', text: '50.0%')
      expect(student_row).to have_selector('td.test-points_earned', exact_text: '5.0')
      expect(student_row).to have_selector('td.test-points_possible', exact_text: '10.0')
      expect(student_row).to have_selector('td.test-time_spent', exact_text: '01h 05m')
      expect(student_row).to have_selector('td.test-completed_count', text: '1')
      expect(student_row).to have_selector('td.test-assigned_count', text: '1')

      # Change the focus to the first section
      wait_for_next_page do
        visit(
          gradebook_engine.course_reports_path(
            course_id: course.id, program_id: program.id, section_id: section.id
          )
        )
      end

      # Click the Delete link for the report
      within(report_row(report)) { click_link('Delete') }

      # Click the button to confirm deletion
      click_button('Delete')

      # I should be on the reports index page
      expect_url(reports_index_url)

      # The report I deleted should be gone
      expect(page).to have_no_selector(name_selector, text: new_report_name)

      # I should see a flash message confirming deletion.
      expect_flash_message(:notice, "Successfully deleted #{new_report_name}")
    end

    scenario "As an instructor, I cannot get to other instructors' reports" do
      my_report = GradebookEngine::Report.create!(
        data_columns: ['percentage'],
        first_lesson_id: activity.lesson.id,
        last_lesson_id: activity.lesson.id,
        level: 'Cumulative',
        name: 'my report',
        owner_id: instructor.id,
        program_id: program.id
      )

      not_my_report = GradebookEngine::Report.create!(
        data_columns: ['percentage'],
        first_lesson_id: activity.lesson.id,
        last_lesson_id: activity.lesson.id,
        level: 'Cumulative',
        name: 'other instructor report',
        owner_id: create(:instructor).id,
        program_id: program.id
      )

      common_report_params = { course_id: course.id, program_id: program.id }
      my_report_params     = common_report_params.merge(id: my_report.id)
      other_report_params  = common_report_params.merge(id: not_my_report.id)

      # purpose: I cannot access the :show action for another user's report
      visit gradebook_engine.course_report_path(other_report_params)
      expect_access_to_be_denied

      # purpose: I cannot access the :edit action for another user's report
      visit gradebook_engine.edit_course_report_path(other_report_params)
      expect_access_to_be_denied

      # purpose: I cannot access the :run action for another user's report
      # step: Go to the edit form for my own report
      visit gradebook_engine.edit_course_report_path(my_report_params)

      # step: Hack the form to POST to the :run action for another report id.
      new_action = gradebook_engine.run_course_report_path(other_report_params)
      page.execute_script(
        "$('form[action*=reports]').attr('action', '#{new_action}');"
      )

      wait_for_next_page do
        click_button('Run Report')
      end
      expect_access_to_be_denied

      # purpose: I cannot submit to the :update action for another user's report
      # step: Go to the run view for a report I'm allowed to access
      visit gradebook_engine.course_report_path(my_report_params)

      # step: Open the Save dialog and enter a different name
      click_link('Save Template')
      fill_in('Name this report', with: 'Haha, I hacked your report!')

      # step: Hack the form in the modal to PUT to the :update action for
      # another report id
      new_action = gradebook_engine.course_report_path(other_report_params)
      page.execute_script(
        "$('form.edit_report').attr('action', '#{new_action}');"
      )

      click_button('Save')
      expect_access_to_be_denied

      # purpose: I cannot submit to the :destroy action for another user's report
      # step: Hack the hidden form for the delete button to send DELETE to
      # another report id.
      new_action = gradebook_engine.course_report_path(other_report_params)
      page.execute_script("$('.js-delete-link').attr('data-path', '#{new_action}');")

      # step: Click Delete and confirm deletion.
      within(report_row(my_report)) { click_link('Delete') }
      click_button('Delete')

      expect_access_to_be_denied(include_section_id: false)
    end
  end

  describe 'in programs with units and lessons' do
    let(:program) { create(:two_tier_program_with_unit_in_lesson_names) }

    scenario 'As an instructor, I can manage reports in a two-tier program ' do
      log_in_as(instructor)
      # Assign and add a submission for activity in first lesson of first unit.
      create(
        :assignment,
        assignable: activity,
        category: category_1,
        due_date: 2.days.ago,
        section: section
      )
      create_gradebook_engine_submission(
        activity: activity,
        pending: false,
        points_earned: 2.0,
        section: section,
        submitted_at: 3.days.ago.to_date,
        student: student_1,
        time_spent: 3_600
      )

      # Create an activity in second lesson of first unit, assign and add a submission.
      unit_1_lesson_2 = program.units.first.lessons.last
      unit_1_lesson_2_activity = create_activity_with_unit_lesson_and_concept(
        program,
        lesson: unit_1_lesson_2,
        points_possible: 10,
        strand_id: unit_1_lesson_2.strands.first.location
      )
      create(
        :assignment,
        assignable: unit_1_lesson_2_activity,
        category: category_1,
        due_date: 2.days.ago,
        section: section
      )
      create_gradebook_engine_submission(
        activity: unit_1_lesson_2_activity,
        pending: false,
        points_earned: 3.0,
        section: section,
        submitted_at: 3.days.ago.to_date,
        student: student_1,
        time_spent: 91 # To test rounding up to nearest minute
      )

      # Create an activity in first lesson of second unit, assign and add a submission.
      unit_2_lesson_1 = program.units[1].lessons.first
      unit_2_lesson_1_activity = create_activity_with_unit_lesson_and_concept(
        program,
        lesson: unit_2_lesson_1,
        points_possible: 10,
        strand_id: unit_2_lesson_1.strands.first.location
      )
      create(
        :assignment,
        assignable: unit_2_lesson_1_activity,
        category: category_1,
        due_date: 2.days.ago,
        section: section
      )
      create_gradebook_engine_submission(
        activity: unit_2_lesson_1_activity,
        pending: false,
        points_earned: 7.0,
        section: section,
        submitted_at: 3.days.ago.to_date,
        student: student_1,
        time_spent: 60
      )

      # Go to the new reports form
      wait_for_next_page do
        visit gradebook_engine.new_course_report_path(
          course_id: course.id, program_id: program.id, section_id: section.id
        )
      end

      lessons = section.lessons_covered

      # Verify default initial values

      # For lesson range, the first and last lessons of the course should be
      # selected by default
      expect(find('#report_first_lesson_id').value).to eq(lessons.first.id.to_s)
      expect(find('#report_last_lesson_id').value).to eq(lessons.last.id.to_s)

      # Verify that all options show up in edit form. Incorrect config of
      # the rails select helper could result in first lesson not showing.
      options = selectbox_options(:report_first_lesson_id)
      option_ids = options.map { |option| option['value'].to_i }

      expect(options.map(&:text)).to eq(lessons.map(&:name))
      close_selectbox_menu(:report_first_lesson_id)

      expect(page).to have_unchecked_field('Unit')

      vhl_choose('Unit', allow_label_click: true)

      # Choose all the fields
      vhl_check('Percentage', allow_label_click: true)
      vhl_check('Points Earned', allow_label_click: true)
      vhl_check('Points Possible', allow_label_click: true)
      vhl_check('Time Spent', allow_label_click: true)
      vhl_check('Activities Assigned', allow_label_click: true)
      vhl_check('Activities Completed', allow_label_click: true)

      click_button('Run Report')

      # I should see the student's grade for:
      # Unit 1: 2/10 + 3/10 = 5 / 20: 20 %
      # Unit 2: 7/10 = 70 %
      student_row = find("tr.test-student#{student_1.id}")
      expect(student_row).to have_selector('td.test-percent', text: '25.0%')
      expect(student_row).to have_selector('td.test-points_earned', exact_text: '5.0')
      expect(student_row).to have_selector('td.test-points_possible', exact_text: '20.0')
      expect(student_row).to have_selector('td.test-time_spent', exact_text: '01h 02m')
      expect(student_row).to have_selector('td.test-completed_count', text: '2')
      expect(student_row).to have_selector('td.test-assigned_count', text: '2')
    end

    scenario 'As an instructor team member, I can manage reports in a section ' \
             'for which I am a team member' do
      co_instructor = create(:instructor)

      # Create SectionInstructor record to make this user a co-instructor of
      # the second section. Needs to be second section to set up a case that
      # was causing a bug, where we redirected to course.sections.first, which
      # the logged in user was not a co-instructor on.
      create(:section_co_instructor, section: section_2, instructor: co_instructor)
      initialize_program_access_client_calls_for_instructor(co_instructor, program)
      log_in_as(co_instructor)

      wait_for_next_page do
        visit gradebook_engine.course_section_scores_path(
          course_id: course.id, program_id: program.id, section_id: section_2.id
        )
      end

      find('.c-subnav__link', text: 'Reports').click
      click_link('Create New Report')
      click_button('Run Report')
      click_link('Save Template')

      old_name = 'co-instructor report'
      fill_in('Name this report', with: old_name)
      click_button('Save')

      expect_flash_message(:notice, "Successfully saved settings as #{old_name}")
      expect(find(name_selector)).to have_text(old_name)
      click_edit_report_link
      click_button('Run Report')
      click_link('Save Template')

      new_name = 'edited co-instructor report'
      fill_in('Name this report', with: new_name)
      click_button('Save')
      expect_flash_message(:notice, "Successfully saved settings as #{new_name}")
      expect(find(name_selector)).to have_text(new_name)
    end
  end
end
