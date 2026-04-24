feature 'Single student view',
        chrome: true, js: true, new_gb_sync: true do
  include ActiveSupport::Testing::TimeHelpers
  include GradebookEngineHelpers
  include RspecJsApiHelpers
  include RspecJsCommonHelpers

  Time::DATE_FORMATS.merge!(
    short_month_with_time: '%b %d %I:%M %p'
  )

  def due_date_string(date)
    due_date = date + section.due_time.seconds_since_midnight.seconds
    due_date.to_formatted_s(:short_month_with_time)
  end

  def day_select
    find('select[name="activities_strand_or_day"]')
  end

  # create program
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, unit: unit) }
  let(:concept) { create(:concept, lesson: lesson) }

  # create instructor and student
  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:other_student) { create(:student) }

  # create course and section; enroll student
  let(:course) do
    create(
      :course,
      owner: instructor,
      program: program,
      start_date: Date.new(2022, 8, 14)
    )
  end

  let(:section) do
    create(
      :section,
      course: course,
      instructor: instructor,
      days_to_show_assignment_due_date: 5
    )
  end

  let(:category) do
    create(
      :category,
      course: course,
      weighting_percent: 100
    )
  end

  let(:now) { course.start_date + 3.weeks + 3.days }

  ########################################
  # Assignments
  ########################################

  let(:activities) { create_list(:activity, 9, concept: concept, lesson: lesson) }
  let(:activity_for_week1day1) { activities[0] }
  let(:activity_for_week1day2) { activities[1] }
  let(:activity_for_week1day3) { activities[2] }
  let(:activity_for_week1day4) { activities[3] }
  let(:activity_for_week2day1) { activities[4] }
  let(:activity_for_released_regular_assignment) { activities[5] }
  let(:activity_for_unreleased_regular_assignment) { activities[6] }
  let(:activity_for_released_individual_assignment) { activities[7] }
  let(:activity_for_unreleased_individual_assignment) { activities[8] }

  # This assignment is for the whole section.
  # It should appear when we filter for week 1,
  # and its due date should appear in the strand-or-day select.
  let(:assignment_week1day1) do
    create(
      :assignment,
      assignable: activity_for_week1day1,
      category: category,
      due_date: course.start_date + 1.day,
      individually_assignable: false,
      section: section
    )
  end

  # This is the parent assignment for assignment_week1day2_indiv_same,
  # which does not override the default due date.
  # It should appear when we filter for week 1,
  # and its due date should appear in the strand-or-day select.
  let(:assignment_week1day2) do
    create(
      :assignment,
      assignable: activity_for_week1day2,
      category: category,
      due_date: course.start_date + 2.days,
      individually_assignable: true,
      section: section
    )
  end

  let(:assignment_week1day2_indiv_same) do
    create(
      :individual_assignment,
      activity_id: assignment_week1day2.assignable_id,
      due_date: nil,
      section_id: section.id,
      user_id: student.id
    )
  end

  # This is the parent assignment for assignment_week1day3_indiv_week2day3,
  # which overrides the due date with a date in week 2.
  # It should _not_ appear when we filter for week 1,
  # and its due date should _not_ appear in the strand-or-day select.
  let(:assignment_week1day3) do
    create(
      :assignment,
      assignable: activity_for_week1day3,
      category: category,
      due_date: course.start_date + 3.days,
      individually_assignable: true,
      section: section
    )
  end

  let(:assignment_week1day3_indiv_week2day3) do
    create(
      :individual_assignment,
      activity_id: assignment_week1day3.assignable_id,
      due_date: assignment_week1day3.due_date + 1.week,
      section_id: section.id,
      user_id: student.id
    )
  end

  # This is the parent assignment for assignment_week1day4_indiv_week2day4,
  # which is assigned to a different student.
  # It should _not_ appear when we filter for week 1,
  # and its due date should _not_ appear in the strand-or-day select.
  let(:assignment_week1day4) do
    create(
      :assignment,
      assignable: activity_for_week1day4,
      category: category,
      due_date: course.start_date + 4.days,
      individually_assignable: true,
      section: section
    )
  end

  let(:assignment_week1day4_indiv_week2day4) do
    create(
      :individual_assignment,
      activity_id: assignment_week1day4.assignable_id,
      due_date: assignment_week1day4.due_date + 1.week,
      section_id: section.id,
      user_id: other_student.id
    )
  end

  # This assignment is for the whole section.
  # It should appear when we filter for week 2,
  # and its due date should appear in the strand-or-day select.
  let(:assignment_week2day1) do
    create(
      :assignment,
      assignable: activity_for_week2day1,
      category: category,
      due_date: course.start_date + 8.days,
      individually_assignable: false,
      section: section
    )
  end

  # This is an assignment for the whole section,
  # with a due date fewer than 5 days from now.
  # Because we're within the days_to_show_assignment_due_date
  # threshold, it should appear.
  let(:released_regular_assignment) do
    create(
      :assignment,
      assignable: activity_for_released_regular_assignment,
      category: category,
      due_date: now + 3.days,
      section: section
    )
  end

  # This is an assignment for the whole section,
  # with a due date more than 5 days from now.
  # Because we're not yet within the days_to_show_assignment_due_date
  # threshold, it should _not_ appear.
  let(:unreleased_regular_assignment) do
    create(
      :assignment,
      assignable: activity_for_unreleased_regular_assignment,
      category: category,
      due_date: now + 7.days,
      section: section
    )
  end

  # This is an individual assignment,
  # with a custom due date fewer than 5 days from now.
  # Because we're within the days_to_show_assignment_due_date
  # threshold, it should appear.
  let(:individual_assignment_released) do
    assignment = create(
      :assignment,
      assignable: activity_for_released_individual_assignment,
      category: category,
      due_date: now + 7.days,
      individually_assignable: true,
      section: section
    )

    create(
      :individual_assignment,
      activity_id: assignment.assignable_id,
      due_date: now + 3.days,
      section_id: section.id,
      user_id: student.id
    )
  end

  # This is an individual assignment,
  # with a custom due date more than 5 days from now.
  # Because we're not yet within the days_to_show_assignment_due_date
  # threshold, it should _not_ appear.
  let(:individual_assignment_not_released) do
    assignment = create(
      :assignment,
      assignable: activity_for_unreleased_individual_assignment,
      category: category,
      due_date: now + 3.days,
      individually_assignable: true,
      section: section
    )

    create(
      :individual_assignment,
      activity_id: assignment.assignable_id,
      due_date: now + 7.days,
      section_id: section.id,
      user_id: student.id
    )
  end

  ########################################
  # Test classes
  ########################################
  let(:test_class_day_1) { "test-user_#{student.id}_grade_#{activity_for_week1day1.id}" }
  let(:test_class_day_2) { "test-user_#{student.id}_grade_#{activity_for_week1day2.id}" }

  let(:test_class_indiv_week1day3) do
    "test-user_#{student.id}_grade_#{activity_for_week1day3.id}"
  end

  let(:test_class_week2day1) { "test-user_#{student.id}_grade_#{activity_for_week2day1.id}" }

  let(:effective_due_dates) do
    [
      assignment_week1day1.due_date,
      assignment_week1day2_indiv_same.effective_due_date,
      assignment_week1day3_indiv_week2day3.effective_due_date,
      assignment_week1day4_indiv_week2day4.effective_due_date,
      released_regular_assignment.due_date,
      unreleased_regular_assignment.due_date,
      individual_assignment_released.effective_due_date,
      individual_assignment_not_released.effective_due_date,
      assignment_week2day1.due_date
    ]
  end

  let(:due_date_released_string) do
    due_date_string(now + 3.days)
  end

  let(:activity_ids_released) do
    [
      activity_for_released_regular_assignment.id,
      activity_for_released_individual_assignment.id
    ]
  end

  let(:activity_ids_not_released) do
    [
      activity_for_unreleased_regular_assignment.id,
      activity_for_unreleased_individual_assignment.id
    ]
  end

  scenario 'As a student viewing my scores in the gradebook, I see expected due dates' do
    step 'Create submissions for assignments' do
      # One of these assignments (...week1day4) is not for the student,
      # but creating the extra submission doesn't affect the specs.
      activities.zip(effective_due_dates) do |activity, due_date|
        create_gradebook_engine_submission(
          activity: activity,
          section: section,
          submitted_at: due_date - 1.day,
          student: student
        )
      end

      # Create the submission for the other student's assignment also.
      create_gradebook_engine_submission(
        activity: activity_for_week1day4,
        section: section,
        submitted_at: assignment_week1day4.due_date - 1.day,
        student: other_student
      )
    end

    step 'Set up students; time-travel; log in' do
      stub_request(:get, %r{^https://ps.pndsn.com/*})
        .to_return(status: 200, body: '', headers: {})

      create(:enrollment, user: student, section: section)
      create(:enrollment, user: other_student, section: section)
      travel_to now
      initialize_program_access_client_calls_for_user_and_program(student, program)
      log_in_as(student)
    end

    step 'Navigate to student scores' do
      visit course_section_path(
        course_id: course.id, section_id: section.id
      )
      click_on('Grades')
      click_on('Scores')
    end

    step 'Assert presence/absence of rows, correct due dates' do
      # The first three assignments all should appear.
      expect(
        find(".test-user_#{student.id}_grade_#{activity_for_week1day1.id}__due-date")
      ).to have_content(
        due_date_string(assignment_week1day1.due_date)
      )

      expect(
        find(".test-user_#{student.id}_grade_#{activity_for_week1day2.id}__due-date")
      ).to have_content(
        due_date_string(assignment_week1day2_indiv_same.effective_due_date)
      )

      expect(
        find(".test-user_#{student.id}_grade_#{activity_for_week1day3.id}__due-date")
      ).to have_content(
        due_date_string(assignment_week1day3_indiv_week2day3.due_date)
      )

      # The fourth assignment is not assigned to the current user and should not appear.
      expect(page).not_to have_selector(
        ".test-user_#{student.id}_grade_#{activity_for_week1day4.id}__due-date"
      )

      # The two assignments that are due fewer than five days from now should appear.
      activity_ids_released.each do |id|
        expect(
          find(".test-user_#{student.id}_grade_#{id}__due-date")
        ).to have_content(due_date_released_string)
      end

      # The two assignments that are due more than five days from now should not appear.
      activity_ids_not_released.each do |id|
        expect(page).not_to have_selector(".test-user-#{student.id}-grade-#{id}__due-date")
      end
    end

    step 'Select week 1 and assert presence/absence of rows, correct due dates' do
      select('Due Date', from: 'lesson_or_due_date')
      select('Week 1:', from: 'all_lesson_or_week', exact: false)

      #########################################
      # Check the table rows
      #########################################

      # The first two assignments fall within week 1 and should appear.
      expect(
        find(".test-user_#{student.id}_grade_#{activity_for_week1day1.id}__due-date")
      ).to have_content(
        due_date_string(assignment_week1day1.due_date)
      )

      expect(
        find(".test-user_#{student.id}_grade_#{activity_for_week1day2.id}__due-date")
      ).to have_content(
        due_date_string(assignment_week1day2_indiv_same.effective_due_date)
      )

      # The third assignment's custom due date falls in week 2 and should not appear.
      expect(page).not_to have_selector(
        ".test-user_#{student.id}_grade_#{activity_for_week1day3.id}__due-date"
      )

      # The fourth assignment is not assigned to the current user and should not appear.
      expect(page).not_to have_selector(
        ".test-user_#{student.id}_grade_#{activity_for_week1day4.id}__due-date"
      )

      #########################################
      # Check the dates in the
      # strand_or_day select
      #########################################

      # The dates for the first two assignments only should appear.
      day_select_elm = day_select

      expect(day_select_elm).to have_selector("option[value='#{assignment_week1day1.due_date}']")
      expect(day_select_elm).to have_selector("option[value='#{assignment_week1day2.due_date}']")

      expect(day_select_elm).not_to have_selector(
        "option[value='#{assignment_week1day3.due_date}']"
      )

      expect(day_select_elm).not_to have_selector(
        "option[value='#{assignment_week1day4.due_date}']"
      )

      #########################################
      # Check that selecting a day restricts
      # the assignments in the table to that
      # day only
      #########################################

      select(
        assignment_week1day1.due_date.strftime('%-m/%-d/%y'),
        from: 'activities_strand_or_day'
      )

      expect(page).to have_selector("tr.#{test_class_day_1}")
      expect(page).not_to have_selector("tr.#{test_class_day_2}")

      select(
        assignment_week1day2.due_date.strftime('%-m/%-d/%y'),
        from: 'activities_strand_or_day'
      )

      expect(page).to have_selector("tr.#{test_class_day_2}")
      expect(page).not_to have_selector("tr.#{test_class_day_1}")
    end

    step 'Select week 2 and assert presence of individual assignment for week 2' do
      select('Week 2:', from: 'all_lesson_or_week', exact: false)

      # NOTE: The assignment for week 1 day 3 is expected to appear in the week 2 view
      #       because the individual assignment for the student overrides the default
      #       due date with a due date in week 2.

      #########################################
      # Check the table rows
      #########################################

      expect(page).to have_selector("tr.#{test_class_indiv_week1day3}")
      expect(page).to have_selector("tr.#{test_class_week2day1}")
      expect(find("td.#{test_class_indiv_week1day3}__due-date")).to have_text(
        due_date_string(assignment_week1day3_indiv_week2day3.due_date)
      )
      expect(find("td.#{test_class_week2day1}__due-date")).to have_text(
        due_date_string(assignment_week2day1.due_date)
      )

      #########################################
      # Check the dates in the
      # strand_or_day select
      #########################################
      expect(day_select).to have_selector(
        "option[value='#{assignment_week1day3_indiv_week2day3.due_date}']"
      )
      expect(day_select).to have_selector(
        "option[value='#{assignment_week2day1.due_date}']"
      )

      #########################################
      # Check that selecting a day restricts
      # the assignments in the table to that
      # day only
      #########################################
      select(
        assignment_week1day3_indiv_week2day3.due_date.strftime('%-m/%-d/%y'),
        from: 'activities_strand_or_day'
      )

      expect(page).to have_selector("tr.#{test_class_indiv_week1day3}")
      expect(page).not_to have_selector("tr.#{test_class_week2day1}")

      select(
        assignment_week2day1.due_date.strftime('%-m/%-d/%y'),
        from: 'activities_strand_or_day'
      )

      expect(page).to have_selector("tr.#{test_class_week2day1}")
      expect(page).not_to have_selector("tr.#{test_class_indiv_week1day3}")
    end

    step 'check week 2, this time as instructor' do
      initialize_program_access_client_calls_for_user_and_program(instructor, program)
      log_in_as(instructor)

      visit GradebookEngine::Engine.routes.url_helpers.section_user_overview_path(
        program.id, section.id, student.id
      )
      click_on('Scores')
      select('Due Date', from: 'lesson_or_due_date')
      select('Week 2:', from: 'all_lesson_or_week', exact: false)

      expect(page).to have_selector("tr.#{test_class_indiv_week1day3}")
      expect(page).to have_selector("tr.#{test_class_week2day1}")
      expect(find("td.#{test_class_indiv_week1day3}__due-date")).to have_text(
        due_date_string(assignment_week1day3_indiv_week2day3.due_date)
      )
      expect(find("td.#{test_class_week2day1}__due-date")).to have_text(
        due_date_string(assignment_week2day1.due_date)
      )

      #########################################
      # Check the dates in the
      # strand_or_day select
      #########################################
      expect(day_select).to have_selector(
        "option[value='#{assignment_week1day3_indiv_week2day3.due_date}']"
      )
      expect(day_select).to have_selector(
        "option[value='#{assignment_week2day1.due_date}']"
      )

      #########################################
      # Check that selecting a day restricts
      # the assignments in the table to that
      # day only
      #########################################
      select(
        assignment_week1day3_indiv_week2day3.due_date.strftime('%-m/%-d/%y'),
        from: 'activities_strand_or_day'
      )

      expect(page).to have_selector("tr.#{test_class_indiv_week1day3}")
      expect(page).not_to have_selector("tr.#{test_class_week2day1}")

      select(
        assignment_week2day1.due_date.strftime('%-m/%-d/%y'),
        from: 'activities_strand_or_day'
      )

      expect(page).to have_selector("tr.#{test_class_week2day1}")
      expect(page).not_to have_selector("tr.#{test_class_indiv_week1day3}")
    end

    travel_back
  end
end
