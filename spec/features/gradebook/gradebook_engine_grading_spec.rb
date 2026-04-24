feature 'Grading student work from the gradebook',
        chrome: true, js: true, new_gb_sync: true, type: :feature do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers
  include GradebookEngineTest::PageObjects
  include Capybara::Angular::DSL
  include CapybaraViewHelpers
  include WaitForNextPage

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:category) { create(:category, course: course, penalty_percent: 0) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  # activity is defined within context blocks so we can define it differently
  # to test auto-graded and instructor-graded functionality.

  let(:concept) { activity.concept }
  let(:lesson) { activity.lesson }
  let(:strand) { activity.strand }

  let(:attempt_results) { blank_open_ended_results(activity) }

  # Some functionality still only exists in the sandbox.
  def sandbox_activities_for_lesson_url
    gradebook_engine.sandbox_program_course_gradebook_path(
      program.id,
      course.id,
      level: 'activity',
      summary_level: 'lesson',
      summary_level_id: lesson.id
    )
  end

  def open_student_grade_modal
    find(student_grade_selector).click
  end

  def find_rubric_link
    target_url = scored_rubric_section_activity_path(section, activity)
    link = find(".js-modal-content a[href^='#{target_url}']", text: 'Rubric Details')
    expect(link).to be_visible
  end

  def find_and_click_grading_link(link_name)
    # Ensure we see the review work link and that it is going to the right
    # action.
    target_url = instructor_review_work_grade_path(program, section, student, activity)

    # Need to use this instead of find_link because we want to find the link
    # that starts with the target url vs an exact match, so we don't have to
    # deal with trying to match the return_to query parameter of the link.
    link = find(".js-modal-content a[href^='#{target_url}']", text: link_name)
    expect(link).to be_visible

    # Now lets review some work.
    link.click
  end

  def find_and_click_done_button
    submit_button = find(:css, "input.done[value='Save & Done']")
    scroll_to(submit_button)
    click_button('Save & Done', visible: true)
  end

  def grade_all_questions_for_student
    @page_object.student_answer('question_01', student).score = 10.0
    @page_object.student_answer('question_02', student).score = 10.0
    @page_object.student_answer('question_03', student).score = 10.0
    @page_object.student_answer('question_04', student).score = 10.0
    @page_object.button(:done).click
  end

  # Assigns the passed in score to each criteria input for the question.
  def grade_all_rubric_questions_for_student(score, method = 'rubric')
    @page_object.student_answer('question_01', student).rubric_score(score, method)
    find('body').click # need to blur the final criteria field
    @page_object.button(:done).click
  end

  def validate_grading_in_gradebook(points)
    score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
      student.id, section.id, activity.id
    ).first
    expect(score_action.points_earned.to_f).to eq(points.to_f)
    expect(score_action.pending).to be_falsey
  end

  def switch_grading_method(method)
    find('#grading-method-toggle').find(:option, method).select_option
    click_button 'Clear Scores'
  end

  before do
    create(:enrollment, user: student, section: section)
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: Date.yesterday,
      section: section
    )
    create(:attempt_completed, activity: activity, section: section, user: student)
    allow_any_instance_of(Attempt).to receive(:results) { attempt_results }
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  context 'with an auto-graded activity' do
    let(:activity) { create_multiple_choice_activity(program) }

    scenario 'As an instructor I can see a link to review work for each ' \
      'submitted student attempt that has grading' do
      # The student has submitted the activity
      create_gradebook_engine_submission(submitted_at: Time.now.utc)

      # Go to the gradebook page showing activity-level scores.
      visit activities_for_lesson_url

      # Click the score to bring up the modal.
      open_student_grade_modal

      find_and_click_grading_link('Review Student Work')

      # Override the score for the first question from 0 points to 2 points.
      fill_in("score_for_question_01_student_#{student.id}", with: '2')

      # Submit the review work form.
      wait_for_next_page do
        find_and_click_done_button
      end

      # Verify their score got changed.
      score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
        student.id, section.id, activity.id
      ).first
      expect(score_action.points_earned.to_f).to eq(2.0)

      # Verify that we were returned to the same gradebook view that we
      # started from.
      expect_url(activities_for_lesson_url)
    end
  end

  context 'with an assessment' do
    let(:activity) { create_open_ended_assessment(program) }

    scenario 'As an instructor, I can grade an instructor-graded ' \
      'assessment for a single student' do
      assignment = Assignment.where(assignable_id: activity.id).first
      assignment.update!(
        grade_availability: 'on_due_date',
        show_assessment: 'a specific date and time',
        show_at: 2.days.ago
      )

      create_gradebook_engine_submission(submitted_at: 2.days.ago)

      visit activities_for_lesson_url

      open_student_grade_modal

      find_and_click_grading_link('Grade this Assignment')

      for_grading_assignment do |pobject|
        grade_all_questions_for_student
      end

      validate_grading_in_gradebook(40.0)
    end
  end

  context 'with a rubric activity' do
    let(:activity) { create_composition_activity_with_rubric(program) }
    let(:attempt_results) { blank_composition_results(activity) }

    scenario 'As an instructor, I can access student-by-student and review work' \
             'grading for an instructor-graded activity' do

      create_gradebook_engine_submission(submitted_at: Time.now.utc)

      # Go to the gradebook page showing activity-level scores
      # & enter grading for submitted activity
      visit activities_for_lesson_url
      column_header(activity).click
      click_link('Grade Activity')
      click_on('start grading')

      # Confirm that rubric grading method is pre-selected
      expect(page.find('#grading-method-toggle').value).to eq('rubric')

      # Confirm comment box presence & visibility
      comment_checkbox = page.find('#show_hide_comments')
      text_selector = ".js-comment-for-question_01-student-#{student.id} " \
                      '.instructor_comment_area.js-accent_bar_container'
      text_comment_elm = page.find(text_selector)
      record_selector = ".js-comment-for-question_01-student-#{student.id} " \
                        '.instructor_comment_area.recorded_comment'
      recorded_comment_elm = page.find(record_selector)
      comment_checkbox.check
      expect(text_comment_elm).to be_visible
      expect(recorded_comment_elm).to be_visible

      comment_checkbox.uncheck
      expect(text_comment_elm).not_to be_visible
      expect(recorded_comment_elm).not_to be_visible

      # Confirm student name presence & visibility
      names_checkbox = page.find('#show_hide_student_names')
      student_name_elm = page.find('.student_name')
      student_number_elm = page.find('.student_number')

      names_checkbox.check
      expect(student_name_elm).to be_visible
      expect(student_number_elm).not_to be_visible

      names_checkbox.uncheck
      expect(student_name_elm).not_to be_visible
      expect(student_number_elm).to be_visible

      for_grading_student_by_student do
        # Confirm rubric toolbar appears when clicking rubric inputs
        find("#criteria-0-#{student.id}").click
        expect(page).to have_selector('.c-rubric-toolbar')

        # Confirm rubric toolbar hides with manual grading
        switch_grading_method('manual')
        expect(page).not_to have_selector('.c-rubric-toolbar')

        # Confirm grading by rubric works
        switch_grading_method('rubric')
        grade_all_rubric_questions_for_student(5)
      end

      # Confirm score is correct in gradebook
      expect_url(activities_for_lesson_url)
      validate_grading_in_gradebook(15)
      open_student_grade_modal
      find_rubric_link

      # Return to grading and confirm manual grading works
      find_and_click_grading_link('Review Student Work')

      for_grading_student_by_student do
        # Confirm page initializes with rubric grading controls
        expect(page.find('#grading-method-toggle').value).to eq('rubric')
        switch_grading_method('manual')
        grade_all_rubric_questions_for_student(6, 'manual')
      end

      expect_url(activities_for_lesson_url)
      validate_grading_in_gradebook(6)
    end
  end

  context 'with an instructor-graded activity' do
    let(:activity) { create_open_ended_activity(program) }

    scenario 'As an instructor, I can access student-by-student grading for ' \
      'any instructor-graded activity' do
      # The student has submitted the activity
      create_gradebook_engine_submission(submitted_at: Time.now.utc)

      # Go to the gradebook page showing activity-level scores.
      visit activities_for_lesson_url
      column_header(activity).click
      click_link('Grade Activity')
      click_on('start grading')

      for_grading_student_by_student do |pobject|
        grade_all_questions_for_student
      end

      # Verify that we were returned to the same gradebook view that we
      # started from.
      expect_url(activities_for_lesson_url)

      validate_grading_in_gradebook(40.0)
    end

    scenario 'As an instructor, I can grade an instructor-graded ' \
      'activity for a single student' do
      create_gradebook_engine_submission(submitted_at: 3.days.ago)

      # Go to the gradebook page showing activity-level scores.
      visit activities_for_lesson_url

      open_student_grade_modal

      find_and_click_grading_link('Grade this Assignment')

      for_grading_assignment do |pobject|
        grade_all_questions_for_student
      end

      validate_grading_in_gradebook(40.0)

      # Verify that we were returned to the same gradebook view that we
      # started from.
      expect_url(activities_for_lesson_url)

      # Don't show is-adjusted icon for this grade.
      expect(page).not_to have_css(".is-adjusted > #{student_grade_selector}")
    end

    scenario 'As an instructor, I can adjust points earned for an ' \
             'instructor-graded activity with zero points' do
      create_gradebook_engine_submission(submitted_at: 3.days.ago)

      score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
        student.id, section.id, activity.id
      ).first

      expect(score_action).to be_pending

      step 'Visit the gradebook page, viewing scores by lesson' do
        visit activities_for_lesson_url
      end

      step 'Open student grade modal' do
        open_student_grade_modal
      end

      purpose 'Instructor should see the option to adjust earned points' do
        expect(page).to have_content('Change Earned Score')
      end

      step 'Change earned score to zero credit' do
        click_link('Change Earned Score')

        purpose 'The points possible for an activity should be visible' do
          expect(page).to have_content(' / 40 Points')
        end

        click_button('Zero credit')

        wait_for_next_page do
          click_button('Save')
        end

        purpose 'The score action has been updated and is not pending anymore' do
          score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
            student.id, section.id, activity.id
          ).first
          expect(score_action).not_to be_pending
        end

        purpose 'The adjusted earned score for the student should be zero credit now' do
          validate_grading_in_gradebook(0.0)
        end
      end

      purpose 'Validate that the grading tasks are updated with latest changes' do
        visit instructor_dashboard_path(program.id)

        expect(page).to have_content('0 Assignments to Grade')

        purpose 'Nothing should appear as needing grading in grading section.' do
          page.find('.test-activities-to-grade .test-assignments_to_grade').click

          expect(page).to have_content('Already graded 1 assignments')
          expect(page).to have_content('Needs grading 0 assignments')
        end
      end
    end

    scenario 'As an instructor, I can adjust points earned for an ' \
             'instructor-graded activity with full credit' do
      create_gradebook_engine_submission(submitted_at: 3.days.ago)

      score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
        student.id, section.id, activity.id
      ).first

      expect(score_action).to be_pending

      step 'Visit the gradebook page, viewing scores by lesson' do
        visit activities_for_lesson_url
      end

      step 'Open student grade modal' do
        open_student_grade_modal
      end

      purpose 'Instructor should see the option to adjust earned points' do
        expect(page).to have_content('Change Earned Score')
      end

      step 'Change earned score to full credit' do
        click_link('Change Earned Score')

        purpose 'The points possible for an activity should be visible' do
          expect(page).to have_content(' / 40 Points')
        end

        click_button('Full credit')

        click_button('Save')

        purpose 'The score action has been updated and is not pending anymore' do
          score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
            student.id, section.id, activity.id
          ).first
          expect(score_action).not_to be_pending
        end

        purpose 'The adjusted earned score for the student should be full credit now' do
          validate_grading_in_gradebook(40.0)
        end
      end

      purpose 'Validate that the grading tasks are updated with latest changes' do
        visit instructor_dashboard_path(program.id)

        expect(page).to have_content('0 Assignments to Grade')

        purpose 'Nothing should appear as needing grading in grading section.' do
          page.find('.test-activities-to-grade .test-assignments_to_grade').click

          expect(page).to have_content('Already graded 1 assignments')
          expect(page).to have_content('Needs grading 0 assignments')
        end
      end
    end
  end

  context 'with an instructor-graded activity via grading-sets' do
    let(:activity) { create_open_ended_activity(program) }

    scenario 'As an instructor, when I do student-by-student grading ' \
      'the student score in the gradebook is updated', retry: 2 do
      # The student has submitted the activity
      create_gradebook_engine_submission(submitted_at: Time.now.utc)

      visit instructor_grading_styles_path(
        program.id,
        activity.id,
        task_type: GradingTask::NEEDS_GRADING
      )

      click_on('start grading')

      for_grading_student_by_student do |pobject|
        grade_all_questions_for_student
      end

      validate_grading_in_gradebook(40.0)
    end

    scenario 'As an instructor, when I do question-by-question grading ' \
      'the student score in the gradebook is updated', test_debt: true do
      # Fails intermittently, not reproducible locally by seed or time of day.
      # Failing build example:
      # https://console.aws.amazon.com/codesuite/codebuild/projects/m3/build/m3:f4bad514-7d32-4267-9b93-0c562e057893/log?region=us-east-1

      # The student has submitted the activity
      create_gradebook_engine_submission(submitted_at: Time.now.utc)

      visit instructor_grading_styles_path(
        program.id,
        activity.id,
        task_type: GradingTask::NEEDS_GRADING
      )

      choose('Question by question')
      click_on('start grading')

      for_grading_question_by_question do |pobject|
        pobject.student_answer('question_01', student).score = 10.0
        pobject.button(:next).click
      end

      for_grading_question_by_question do |pobject|
        pobject.student_answer('question_02', student).score = 10.0
        pobject.button(:next).click
      end

      for_grading_question_by_question do |pobject|
        pobject.student_answer('question_03', student).score = 10.0
        pobject.button(:next).click
      end

      for_grading_question_by_question do |pobject|
        pobject.student_answer('question_04', student).score = 10.0
        @page_object.button(:done).click
      end

      validate_grading_in_gradebook(40.0)
    end
  end

  context 'with an instructor-graded multi-type assessment via grading-sets' do
    let(:activity) { create_mixed_grading_type_assessment(program) }

    scenario 'As an instructor, when I do student-by-student grading ' \
      'the scores in both gradebooks are updated', test_debt: true do
      # Evaluate whether this spec is useful. May be redundant with other
      # grading specs and it references defunct sandbox routes, so it would
      # need to be updated to use the regular gradebook routes.
      assignment = Assignment.where(assignable_id: activity.id).first
      assignment.update!(
        grade_availability: 'on_due_date',
        show_assessment: 'a specific date and time',
        show_at: 2.days.ago
      )

      # The student has submitted the activity
      create_gradebook_engine_submission(submitted_at: Time.now.utc)

      # Go to the gradebook page showing activity-level scores.
      visit sandbox_activities_for_lesson_url

      # Ensule we see the grade activity link and that it is going to the right
      # action.
      target_url = instructor_grading_styles_path(
        program.id,
        activity.id,
        task_type: GradingTask::NEEDS_GRADING
      )
      link = find("a[href^='#{target_url}']", text: 'Grade Activity')
      expect(link).to be_visible

      # Go do some grading.
      link.click

      click_on('start grading')

      fill_in("score_for_question_02_student_#{student.id}", with: '10')
      fill_in("score_for_question_03_student_#{student.id}", with: '10')
      fill_in("score_for_question_04_student_#{student.id}", with: '10')
      find_and_click_done_button

      # Go to the gradebook page showing activity-level scores.
      visit activities_for_lesson_url

      validate_grading_in_gradebook(30.0)
    end
  end

  context 'Redirection when done' do
    let(:activity) { create_open_ended_activity(program) }

    # TODO: Refactor for this and instructor_grading_spec.
    def create_attempt(attrs)
      create(
        :attempt_completed,
        attrs.slice(:activity, :section).merge(user: attrs[:student])
      )
    end

    context 'When returning to previous page after finishing grading' do
      # gradebook; student by student; gradebook
      scenario 'if I arrived at SxS via gradebook, I am returned to the gradebook' do
        # The student has submitted the activity
        create_gradebook_engine_submission(submitted_at: Time.now.utc)

        # Visit grading tasks view first to check that navigating away from it removes
        #   any session state it created.
        visit instructor_grading_tasks_assignments_path(program.id)

        visit activities_for_lesson_url
        column_header(activity).click
        click_link('Grade Activity')
        click_on('start grading')

        for_grading_student_by_student do |pobject|
          grade_all_questions_for_student
        end

        expect_url(activities_for_lesson_url)
        validate_grading_in_gradebook(40.0)
      end

      # gradebook; question by question; gradebook
      scenario 'if I arrived at QxQ via gradebook, I am returned to the ' \
               'gradebook', test_debt: true do
        # Fails intermittently, not reproducible by seed or time of day.
        # Failing build example:
        # https://semaphoreci.com/vhl/m3/branches/master/builds/336

        # The student has submitted the activity
        create_gradebook_engine_submission(submitted_at: Time.now.utc)

        # Visit grading tasks view first to check that navigating away from it removes
        #   any session state it created.
        visit instructor_grading_tasks_assignments_path(program.id)

        visit activities_for_lesson_url
        column_header(activity).click
        click_link('Grade Activity')
        choose('Question by question')
        click_on('start grading')

        for_grading_question_by_question do |pobject|
          pobject.student_answer('question_01', student).score = 10.0
          pobject.button(:next).click
        end

        for_grading_question_by_question do |pobject|
          pobject.student_answer('question_02', student).score = 10.0
          pobject.button(:next).click
        end

        for_grading_question_by_question do |pobject|
          pobject.student_answer('question_03', student).score = 10.0
          pobject.button(:next).click
        end

        for_grading_question_by_question do |pobject|
          pobject.student_answer('question_04', student).score = 10.0
          pobject.button(:done).click
        end

        expect_url(activities_for_lesson_url)
      end

      # gradebook; spotcheck; gradebook
      scenario 'if I arrived at spotcheck via gradebook, I am returned to ' \
        'the gradebook', retry: 2 do
        common_attrs = { activity: activity, section: section }
        attrs = common_attrs.merge(student: student)
        create_gradebook_engine_submission(
          **attrs.merge(pending: true, submitted_at: Time.now.utc, time_spent: 1)
        )

        # Visit grading tasks view first to check that navigating away from it removes
        #   any session state it created.
        visit instructor_grading_tasks_assignments_path(program.id)

        visit activities_for_lesson_url
        column_header(activity).click
        click_link('Grade Activity')
        choose('Spotcheck Student Work')
        click_on('start grading')

        # Start spotcheck grading.
        within('#random_students_spotcheck_start') { click_button('Spotcheck') }

        for_grading_student_by_student do |pobject|
          grade_all_questions_for_student
        end

        for_grading_spotcheck_confirmation_modal(&:finish_spotchecking)

        expect_url(activities_for_lesson_url)
        validate_grading_in_gradebook(40.0)
      end

      # grading; student by student; grading
      scenario 'if I arrived at SxS via grading, I am returned to the grading',
        nondeterministic: true do
        create_gradebook_engine_submission(submitted_at: Time.now.utc)

        # Visit gradebook first to check that navigating away from it removes
        #   any session state it created.
        visit activities_for_lesson_url

        visit instructor_grading_tasks_assignments_path(program.id)
        click_link('Needs grading')
        click_link(activity.title)
        click_on('start grading')

        for_grading_student_by_student do |pobject|
          grade_all_questions_for_student
        end

        expect_url(instructor_grading_tasks_assignments_path(program.id))
        validate_grading_in_gradebook(40.0)
      end

      # grading; question by question; grading
      scenario 'if I arrived at QxQ via grading, I am returned to the grading',
               test_debt: true do
        # Fails intermittently, not reproducible by seed or time of day.
        # Failing build example:
        # https://semaphoreci.com/vhl/m3/branches/master/builds/321

        create_gradebook_engine_submission(submitted_at: Time.now.utc)

        # Visit gradebook first to check that navigating away from it removes
        #   any session state it created.
        visit activities_for_lesson_url

        visit instructor_grading_tasks_assignments_path(program.id)
        click_link('Needs grading')
        click_link(activity.title)
        choose('Question by question')
        click_on('start grading')

        for_grading_question_by_question do |pobject|
          pobject.student_answer('question_01', student).score = 10.0
          pobject.button(:next).click
        end

        for_grading_question_by_question do |pobject|
          pobject.student_answer('question_02', student).score = 10.0
          pobject.button(:next).click
        end

        for_grading_question_by_question do |pobject|
          pobject.student_answer('question_03', student).score = 10.0
          pobject.button(:next).click
        end

        for_grading_question_by_question do |pobject|
          pobject.student_answer('question_04', student).score = 10.0
          pobject.button(:done).click
        end

        expect_url(instructor_grading_tasks_assignments_path(program.id))
      end

      # grading; spotcheck; grading <-- ?
      scenario 'if I arrived at spotcheck via grading, I am returned to ' \
               'the grading', nondeterministic: true do
        common_attrs = { activity: activity, section: section }
        attrs = common_attrs.merge(student: student)
        create_gradebook_engine_submission(
          **attrs.merge(pending: true, submitted_at: Time.now.utc, time_spent: 1)
        )

        # Visit gradebook first to check that navigating away from it removes
        #   any session state it created.
        visit activities_for_lesson_url

        visit instructor_grading_tasks_assignments_path(program.id)
        click_link('Needs grading')
        click_link(activity.title)
        choose('Question by question')
        choose('Spotcheck Student Work')
        click_on('start grading')

        # Start spotcheck grading.
        within('#random_students_spotcheck_start') { click_button('Spotcheck') }

        for_grading_student_by_student do |pobject|
          grade_all_questions_for_student
        end

        for_grading_spotcheck_confirmation_modal(&:finish_spotchecking)

        expect_url(instructor_grading_tasks_assignments_path(program.id))
        validate_grading_in_gradebook(40.0)
      end
    end
  end

  context 'When I choose spotcheck grading' do
    # In the spotcheck grading view, the StudentSorter class sorts the students
    # by name using User.sortable_name. In order to have a predictable spec,
    # we hardcode the student names.
    let(:student_1) { create(:student, first_name: 'Obi-Wan', last_name: 'Kenobi') }
    let(:student_2) { create(:student, first_name: 'Princess', last_name: 'Leia') }
    let(:student_3) { create(:student, first_name: 'Luke', last_name: 'Skywalker') }
    let(:activity) { create_open_ended_assessment(program) }

    before do
      assignment = Assignment.where(assignable_id: activity.id).first
      assignment.update!(
        grade_availability: 'on_due_date',
        show_assessment: 'a specific date and time',
        show_at: 2.days.ago
      )
      [student_1, student_2, student_3].each do |student|
        create(
          :attempt_submitted,
          activity: activity,
          section: section,
          user: student,
          cms_revision_id: activity.cms_revision_id
        )
        create(:enrollment, section: section, user: student)
        create_gradebook_engine_submission(
          submitted_at: 2.days.ago, student: student, pending: true, time_spent: 1)
      end

      initialize_program_access_client_calls_for_instructor(instructor, program)
      log_in_as(instructor)
    end

    scenario 'I can select which student to grade' do
      visit activities_for_lesson_url

      purpose 'I start spotcheck grading' do
        column_header(activity).click
        click_link('Grade Activity')
        for_grading_style_page_object do |pobject|
          pobject.grading_style = :spotcheck
          pobject.start_grading
        end
      end

      for_grading_spotcheck_student_selection do |pobject|
        purpose 'Random style is selected by default' do
          expect(pobject.spotcheck_style).to eq(:random)
        end

        purpose 'I see student 1, 2 and 3' do
          expect(pobject.random_students.map(&:name)).to match_array([
            student_1.last_name_first,
            student_2.last_name_first,
            student_3.last_name_first
          ])
        end

        purpose 'All the students are selected' do
          expect(pobject.random_students.map(&:selected?)).to eq([true, true, true])
        end

        purpose 'I do not see checkbox to individually select students' do
          expect(pobject.random_students.map(&:checkbox_visible?)).to eq([false, false, false])
        end

        purpose 'I choose the number of student to grade' do
          select('1', from: 'select_num_of_random_students')
          expect(pobject.random_students.map(&:selected?)).to eq([true, false, false])
        end

        purpose 'I select all the students' do
          select('All', from: 'select_num_of_random_students')
          expect(pobject.random_students.map(&:selected?)).to eq([true, true, true])
        end

        purpose 'I select the outliers mode' do
          pobject.spotcheck_style = :outliers
        end

        purpose 'I see student 1, 2 and 3' do
          expect(pobject.outliers_students.map(&:name)).to match_array([
            student_1.last_name_first,
            student_2.last_name_first,
            student_3.last_name_first
          ])
        end

        purpose 'All the students are selected' do
          expect(pobject.outliers_students.map(&:selected?)).to eq([true, true, true])
        end

        purpose 'I do not see checkbox to individually select students' do
          expect(pobject.outliers_students.map(&:checkbox_visible?)).to eq([false, false, false])
        end

        purpose 'I choose the number of student to grade' do
          select('2', from: 'select_num_of_outliers')
          expect(pobject.outliers_students.map(&:selected?)).to eq([true, true, false])
        end

        purpose 'I select all the students' do
          select('All', from: 'select_num_of_outliers')
          expect(pobject.outliers_students.map(&:selected?)).to eq([true, true, true])
        end

        purpose 'I select the manual mode' do
          pobject.spotcheck_style = :manual
        end

        purpose 'I see student 1, 2 and 3' do
          expect(pobject.manual_students.map(&:name)).to match_array([
            student_1.last_name_first,
            student_2.last_name_first,
            student_3.last_name_first
          ])
        end

        purpose 'No student is selected' do
          expect(pobject.manual_students.map(&:selected?)).to eq([false, false, false])
        end

        purpose 'I see checkbox to individually select students' do
          expect(pobject.manual_students.map(&:checkbox_visible?)).to eq([true, true, true])
        end

        purpose 'I can not start grading without selecting at least one student' do
          expect(
            accept_alert { pobject.start_grading_button.click }
          ).to start_with('Please select some students for spotchecking!')
        end

        purpose 'I select student 1' do
          pobject.manual_students[0].check
          expect(pobject.manual_students.map(&:selected?)).to eq([true, false, false])
        end

        purpose 'I all the students' do
          pobject.select_all_students
          expect(pobject.manual_students.map(&:selected?)).to eq([true, true, true])
        end

        purpose 'I unselect student 2' do
          pobject.manual_students[1].uncheck
          expect(pobject.manual_students.map(&:selected?)).to eq([true, false, true])
        end

        purpose 'I unselect all the students' do
          pobject.unselect_all_students
          expect(pobject.manual_students.map(&:selected?)).to eq([false, false, false])
        end

        purpose 'I select student 1 and 3' do
          pobject.manual_students[0].check
          pobject.manual_students[2].check
          expect(pobject.manual_students.map(&:selected?)).to eq([true, false, true])
        end

        purpose 'I start grading' do
          pobject.start_grading_button.click
        end

        for_grading_student_by_student do |pobject|
          purpose 'I see the selected students in the drop down' do
            expect(pobject.selectable_students).to contain_exactly(
              student_1.full_name,
              student_3.full_name
            )
          end
        end
      end
    end
  end
end
