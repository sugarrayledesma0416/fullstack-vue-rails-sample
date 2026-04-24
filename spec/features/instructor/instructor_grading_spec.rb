feature 'Instructor grading', chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers
  include GradebookEngineTest::PageObjects
  include InstructorGradingHelpers
  include ActivityTest::MockSubmissions
  include CapybaraViewHelpers

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:students) { [student_1, student_2] }
  let(:other_section_student_1) { create(:student) }
  let(:other_section_student_2) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }
  let(:assessment_program) { create(:program_with_assessment_toc_entries) }
  let(:assessment_lesson) { assessment_program.units.first.lessons.first }
  let(:assessment_strand) { assessment_lesson.strands(true).first }

  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program
    )
  end

  let(:assessment_course) do
    create(
      :course,
      first_unit_id: assessment_program.units.first.id,
      last_unit_id: assessment_program.units.last.id,
      owner: instructor,
      program: assessment_program
    )
  end

  let(:unfocused_course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program
    )
  end

  let(:non_credit_category) do
    create(:category, course: course, credit_only: false)
  end

  let(:credit_category) do
    create(:category, course: course, credit_only: true)
  end

  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:other_section) { create(:section, course: unfocused_course, instructor: instructor) }
  let(:assessment_section) { create(:section, course: assessment_course, instructor: instructor) }

  let(:concept) do
    create(
      :concept,
      assessment: true,
      singular_label: 'quiz',
      id: assessment_strand.location,
      lesson: assessment_lesson,
      program: assessment_program
    )
  end

  let(:assessment_activity) do
    concept
    create_mixed_grading_type_assessment_with_unit_lesson_concept(assessment_program, strand_id: assessment_strand.location)
  end

  let(:fake_submissions) { {} }

  # Data setup helpers
  def create_auto_graded_activity(args = {})
    create_activity(**args.merge(grading_method: 'auto'))
  end

  def create_instructor_graded_activity(args = {})
    create_activity(**args.merge(grading_method: 'instructor'))
  end

  def create_mixed_grading_activity(args = {})
    create_activity(**args.merge(grading_method: 'mixed'))
  end

  def create_activity(grading_method:, title:, **args)
    create_activity_with_unit_lesson_and_concept(
      program,
      grading_method: grading_method,
      lesson: args.fetch(:lesson, lesson),
      strand_id: args.fetch(:strand_id, strand.location),
      title: title
    )
  end

  def create_attempt_and_score(attrs)
    create_attempt(attrs)
    score_attrs = attrs.slice(:activity, :pending, :section, :student).merge(
      submitted_at: attrs.fetch(:submitted_at, 2.days.ago)
    )
    create_gradebook_engine_submission(**score_attrs)
  end

  def create_attempt(attrs)
    create(
      :attempt_completed,
      attrs.slice(:activity, :section).merge(user: attrs[:student])
    )
  end

  # Cycles through an array containing an array of activities of a given
  # type. For each type, assigns the activity at the position specified
  # by index, and calculates some attributes to be passed into submission
  # or assignment setup functions, then yields those attrs, so the calling
  # function can set up the data necessary for the particular case.
  # credit_category, non_credit_category, section, other_section, student_1,
  # student_2, other_section_student_1, and other_section_2 are all pulled
  # from `let` statements.
  def for_activities(types, index, due_date = nil)
    types.each do |activities|
      activity = activities[index]
      # If due_date isn't specify, vary randomly between past and future.
      target_due_date = (due_date || [2.days.ago, 2.days.from_now].sample)
      attrs = {
        activity: activity,
        category: (
          activity.title.starts_with?('credit') ? credit_category : non_credit_category
        ),
        current: (target_due_date < Date.today),
        due_date: target_due_date,
        pending: (activity.grading_method != 'auto'),
        section: (activity.title.starts_with?('other') ? other_section : section),
        first_student: (
          activity.title.starts_with?('other') ? other_section_student_1 : student_1
        ),
        second_student: (
          activity.title.starts_with?('other') ? other_section_student_2 : student_2
        )
      }
      yield attrs
    end
  end

  before do
    allow(Maestro::LicenseGroup).to receive(:all).and_return([])

    initialize_fake_submissions_client
    create(:enrollment, section: section, user: student_1)
    create(:enrollment, section: section, user: student_2)
    create(:enrollment, section: other_section, user: other_section_student_1)
    create(:enrollment, section: other_section, user: other_section_student_2)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'As an instructor, I see the correct activities and counts of ' \
    'submissions to be graded' do
    # Set up activities to cover 5 possible cases
    auto_graded = Array.new(4) do |index|
      create_auto_graded_activity(title: "auto_graded_#{index}")
    end
    instructor_graded = Array.new(4) do |index|
      create_instructor_graded_activity(title: "instructor_graded_#{index}")
    end
    mixed = Array.new(4) do |index|
      create_mixed_grading_activity(title: "mixed_grading_#{index}")
    end
    # Credit only activities and activites to be assigned in another section
    # are just normal instructor-graded activities. They'll be differentiated
    # in the assignment or submission setup steps.
    credit_only = Array.new(4) do |index|
      create_instructor_graded_activity(title: "credit_only_#{index}")
    end
    in_other_section = Array.new(4) do |index|
      create_instructor_graded_activity(title: "other_section_#{index}")
    end
    types = [auto_graded, instructor_graded, mixed, credit_only, in_other_section]

    needs_index = 0
    upcoming_index = 1
    already_index = 2
    unassigned_index = 3

    for_activities(types, needs_index, 2.days.ago) do |attrs|
      create_attempt_and_score(
        attrs.slice(:activity, :current, :pending, :section).merge(
          assigned: true, student: attrs[:first_student]
        )
      )
      create(
        :assignment,
        attrs.slice(:category, :due_date, :section).merge(
          assignable: attrs[:activity]
        )
      )
    end

    for_activities(types, upcoming_index, 2.days.from_now) do |attrs|
      create_attempt_and_score(
        attrs.slice(:activity, :current, :pending, :section).merge(
          assigned: true,
          student: attrs[:first_student]
        )
      )
      create(
        :assignment,
        attrs.slice(:category, :due_date, :section).merge(
          assignable: attrs[:activity]
        )
      )
    end

    for_activities(types, already_index) do |attrs|
      create_attempt_and_score(
        attrs.slice(:activity, :current, :section).merge(
          assigned: true, pending: false, student: attrs[:first_student]
        )
      )
      create_attempt_and_score(
        attrs.slice(:activity, :current, :section).merge(
          assigned: true, pending: false, student: attrs[:second_student]
        )
      )
      create(
        :assignment,
        attrs.slice(:category, :due_date, :section).merge(
          assignable: attrs[:activity]
        )
      )
    end

    for_activities(types, unassigned_index) do |attrs|
      next if attrs[:activity].title.start_with?('credit')
      create_attempt_and_score(
        attrs.slice(:activity, :pending, :section).merge(
          assigned: false, current: false, student: attrs[:first_student]
        )
      )
    end

    ## Part 1: "Needs grading" section
    # Pending, assigned, due, not in credit only category
    visit instructor_grading_tasks_assignments_path(program.id)

    # The sub-section for "Needs grading" activities should show 2 activities
    # to be graded.
    for_instructor_grading_tasks_assignments_page do |pobject|
      expect(pobject.needs_grading_section_count).to eq('2')

      # The detailed activity list should show the instructor-graded activity
      # the mixed grading-type activity. It should not show activity assigned in
      # the credit only category, not the instructor-graded activity
      # submitted by the student in a different course.
      expect_grading_list_item(activity: instructor_graded[needs_index], count: 1)
      expect_grading_list_item(activity: mixed[needs_index], count: 1)
      expect_no_grading_list_item(activity: auto_graded[needs_index])
      expect_no_grading_list_item(activity: credit_only[needs_index])
      expect_no_grading_list_item(activity: in_other_section[needs_index])

      ## Part 2: "Upcoming grading" section

      # The sub-section for already graded activities should show 3 activities
      # to be graded. Unlike the Needs grading section, activities in a
      # credit-only category are displayed in this section.
      expect(pobject.upcoming_grading_section_count).to eq('3')

      click_link('Upcoming grading')

      # The detailed activity list should show the instructor-graded activity
      # the mixed grading-type activity, and the activity assigned in the
      # credit only category. It should not show the instructor-graded activity
      # submitted by the student in a different course.
      expect_grading_list_item(activity: instructor_graded[upcoming_index], count: 1)
      expect_grading_list_item(activity: credit_only[upcoming_index], count: 1)
      expect_grading_list_item(activity: mixed[upcoming_index], count: 1)
      expect_no_grading_list_item(activity: auto_graded[upcoming_index])
      expect_no_grading_list_item(activity: in_other_section[upcoming_index])

      ## Part 3: "Already graded" section
      # Already graded category shouldn't include any activities that are only
      # partially graded (i.e. activities from the first 2 categories).

      # The sub-section for already graded activities should show 3 activities
      # already graded. Unlike the Needs grading section, activities in a
      # credit-only category are displayed in this section.
      expect(pobject.already_graded_section_count).to eq('3')

      click_link('Already graded')

      # The detailed activity list should show the instructor-graded activity
      # the mixed grading-type activity, and the activity assigned in the
      # credit only category. It should not show the instructor-graded activity
      # submitted by the student in a different course.
      expect_grading_list_item(activity: instructor_graded[already_index], count: 2)
      expect_grading_list_item(activity: mixed[already_index], count: 2)
      expect_grading_list_item(activity: credit_only[already_index], count: 2)
      expect_no_grading_list_item(activity: auto_graded[already_index])
      expect_no_grading_list_item(activity: in_other_section[already_index])

      # The instructor graded activities from the Needs Grading and Upcoming
      # grading activities should also not appear in this section.
      expect_no_grading_list_item(activity: instructor_graded[needs_index])
      expect_no_grading_list_item(activity: mixed[needs_index])
      expect_no_grading_list_item(activity: instructor_graded[upcoming_index])
      expect_no_grading_list_item(activity: mixed[upcoming_index])

      ## Part 4: "Unassigned activities" section
      #   Verify that activities with a grading_method of either instructor or
      #   mixed show up in this category, but not auto-graded activities.
      #   Activities that are assigned should not show up, nor should submissions
      #   from students in courses/sections that are not being focused on.
      #   TODO: Items should disappear once graded (pending flag cleared).

      # The sub-section for unassigned activities should show 2 activities
      # to be graded.
      expect(pobject.unassigned_activities_section_count).to eq('2')

      click_link('Unassigned activities')
      # The detailed activity list should show the instructor-graded activity
      # and the mixed grading-type activity, and not the auto-graded activity,
      # nor the instructor-graded activity submitted by the student in a different
      # course.
      expect_grading_list_item(activity: instructor_graded[unassigned_index], count: 1)
      expect_grading_list_item(activity: mixed[unassigned_index], count: 1)
      expect_no_grading_list_item(activity: auto_graded[unassigned_index])
      expect_no_grading_list_item(activity: in_other_section[unassigned_index])
    end
  end

  scenario 'As an instructor, I can do spotcheck grading', retry: 2 do
    # Create an assign an activity in the past that student's won't have
    # submissions for, so we can exercise the Cumulative Grade feature
    # of spotcheck.
    auto_graded_activity = create_auto_graded_activity(title: 'overdue')
    create(
      :assignment,
      assignable: auto_graded_activity,
      category: non_credit_category,
      current: true,
      due_date: 2.days.ago.to_date,
      section: section
    )

    # Set up submissions for two students, with gradebook scores
    activity = create_open_ended_activity(program)
    results = blank_open_ended_results(activity)
    allow_any_instance_of(Attempt).to receive(:results).and_return(results)

    assignment = create(
      :assignment,
      assignable: activity,
      category: non_credit_category,
      current: true,
      due_date: 2.days.ago.to_date,
      section: section
    )

    students = [student_1, student_2]

    common_attrs = { activity: activity, section: section }
    students.each do |student|
      attrs = common_attrs.merge(student: student)
      create_attempt(attrs)
      create_gradebook_engine_submission(
        **attrs.merge(pending: true, submitted_at: 4.days.ago, time_spent: 1)
      )
    end

    visit instructor_grading_tasks_assignments_path(program.id)

    for_instructor_grading_tasks_assignments_page do |pobject|
      # The activity appears under Needs Grading, and has 2 submissions.
      expect(pobject.needs_grading_section_count).to eq('1')
      expect_grading_list_item(activity: activity, count: 2)

      # Choose to Spotcheck the activity
      pobject.grading_list_item(activity).click
    end

    expect(page).to have_no_link('View/Edit Content Settings')
    choose('Spotcheck Student Work')
    click_on('start grading')

    # On the page for selecting spotcheck options, the students' names should
    # appear.
    student_names = all('#random_student_table .students .names').map(&:text)
    expect(student_names).to match_array(students.map(&:last_name_first))

    grades = all('#random_student_list tr.students td:last-child').map(&:text)
    expect(grades).to eq(%w[F F])

    # Start spotcheck grading.
    within('#random_students_spotcheck_start') { click_button('Spotcheck') }

    def student_by_name(name)
      students.detect do |student|
        student.full_name == name
      end
    end

    for_grading_student_by_student do |pobject|
      student = student_by_name(pobject.selected_student)
      %w[question_01 question_02 question_03 question_04].each do |question_label|
        pobject.student_answer(question_label, student).score = 10.0
      end
      pobject.button(:next).click
    end

    for_grading_student_by_student do |pobject|
      student = student_by_name(pobject.selected_student)
      %w[question_01 question_02 question_03 question_04].each do |question_label|
        pobject.student_answer(question_label, student).score = 10.0
      end
      pobject.button(:done).click
    end

    for_grading_spotcheck_confirmation_modal(&:finish_spotchecking)

    # Back on the grading tasks page.
    expect_url(instructor_grading_tasks_assignments_path(program.id))

    # The graded activity has moved from Needs Grading to Already Graded
    for_instructor_grading_tasks_assignments_page do |pobject|
      expect(pobject.needs_grading_section_count).to eq('0')
      expect(pobject.already_graded_section_count).to eq('1')

      # Both students show up as having been graded.
      click_link('Already graded')
      expect_grading_list_item(activity: activity, count: 2)
    end
  end

  scenario 'As an instructor I can grade an activity question by question', test_debt: true  do
    purpose 'setup database' do
      step 'Create a student named "student 1"'
      step 'Create a student named "student 2"'

      step 'Create an open ended activity "open_ended_activity" with 4 questions'
      step '"student 1" has completed "open_ended_activity"'
      step '"student 2" has completed "open_ended_activity", leaving an empty answer for question 1'

      step 'Create a composition activity "composition_activity" with 1 question'
      step '"student 1" has completed "composition_activity" and has uploaded an attachment named "my_response.pdf"'

      step 'Create a multi-type activity "multitype_activity" with 2 auto graded questions and ' \
           '1 open ended question'
      step '"student 1" has completed "multitype_activity"'

      step 'Create an activity "multiple_version_activity" with multiple versions'
      step '"student 1" has completed "multiple_version_activity"'
    end
    step 'Log in as an instructor'

    purpose 'I can grade an activity question by question' do
      step 'Visit the grading tasks assignment page'
      step 'I see "4" assignments in the "Needs grading" section'
      step 'I see "0" assignments in the "Already graded" section'
      step 'I see "2 to be graded" next to "open_ended_activity"'
      step 'Click on "open_ended_activity" link'
      step 'Choose "question by question"'
      step 'Click on "start grading"'
      step 'I see a "view Activity" link'
      step 'I see a dropdown with all the activity questions'
      step 'I see "Question 1" selected in the questions dropdown'

      purpose 'I can show or hide the question prompt' do
        step 'I see the question prompt'
        step 'Click on the "Hide Question" element'
        step 'I do not see the question prompt'
      end

      purpose 'I can show or hide student names' do
        step 'The "student names" checkbox is selected'
        step 'I see the name of student 1'
        step 'I see the name of student 2'
        step 'Uncheck the "student names" checkbox'
        step 'I do not see the name of student 1'
        step 'I see "Student 1"'
        step 'I do not see the name of student 2'
        step 'I see "Student 2"'
      end

      purpose 'I see the submitted answer of each student' do
        # Check that no extra newlines are added to rich text submissions
        # https://vistahl.atlassian.net/browse/MAE-10310
        step 'I see the submitted answer for student 1 without extra lines'
        step 'I see "No student response" for student 2'
      end

      purpose 'I can write or record a comment' do
        step 'I do not see a textarea to write a comment'
        step 'I do not see a button to record a comment'
        step 'Check on the "Comment boxes" checkbox'
        step 'I see a textarea to write a comment for student 1'
        step 'I see a "record" button to record a comment for student 1'
        step 'I see a textarea to write a comment for student 2'
        step 'I see a "record" button to record a comment for student 2'
        step 'Write a comment for student 1'
      end

      purpose 'I can edit answer inline' do
        step "Add text to the student 1's response"
        step "Mark the student 1's response as 'should be deleted'" \
             '(by highlighting and hitting the backspace button)'
      end

      purpose 'I cannot edit answer inline when the student did not submit a response' do
        step "I cannot add text the student 2's response"
        step "I cannot mark the student 2's response as 'should be deleted'"
      end

      purpose 'I do not need to give a score to all students' do
        step 'I see a full credit scoring button'
        step 'I see a zero credit button'
        step 'I give a score of 8 points to student 1'
        step 'I give no score to student 2'
        step 'Click the "next" button'
        step 'I see an alert with the message "You did not enter a grade for 1 student. OK to proceed?"'
        step 'Accept the alert'
      end

      purpose 'I grade the activity' do
        step 'I see "Question 2" selected in the questions dropdown'
        step 'I give a score of 7 points for question 2 for both students'
        step 'Click the "next" button'
        step 'I give a score of 6 points for question 3 for both students'
        step 'Click the "next" button'
        step 'I give a score of 5 points for question 4 for both students'
        step 'Click the "done" button'
        step 'I see the flash message "open_ended_activity has been successfully graded."'
      end
    end

    purpose 'I can restart a partially completed grading set' do
      step 'I see "1 to be graded"'
      step 'Click on "open_ended_activity" link'
      step 'Choose "question by question"'
      step 'Click on "start grading"'
      step 'The first student is "Student 2"'
      step 'student 2 is ungraded'
    end

    purpose 'My comments are saved' do
      step 'I see the comment I left for student 1'
    end

    purpose 'My inline edit of the answer are saved' do
      step "I see the text I added to student 1's response"
      step "I see what I maked as 'should be deleted' in student 1's response"
    end

    purpose 'My scores are saved' do
      step 'I see a score of 8 points to student 1'
      step 'I see no score for student 2'
    end

    step 'I give a score of 1 points for student 2'

    purpose 'I can navigate from question to question' do
      step 'I see question 1'
      step 'Click the "next" button'
      step 'I see question 2'
      step 'Click the "previous" button'
      step 'I see question 1'
      step 'Select "question 4" from the questions dropdown'
      step 'I see question 4'
      step 'Click the "done" button'
      step 'I see the flash message "open_ended_activity has been successfully graded."'
    end

    purpose 'Graded activities are moved from Needs Grading to Already Graded' do
      step 'I see "3" assignments in the "Needs grading" section'
      step 'I see "1" assignment in the "Already graded" section'
    end

    purpose 'When grading an activity I see the changes in the gradebook' do
      step 'Visit the gradebook page'
      step 'I click on the "student 1" link'
      step 'I see a cumulative score of 65%'
      step 'Click on the "score" link'
      step 'I see "65%" in the score column'
      step 'I see "26.0" in the "points earned" column'
      step 'I see "40.0" in the "points possible" column'
    end

    purpose 'I can grade composition activity' do
      step 'Visit the grading tasks assignment page'
      step 'Click on "composition_activity" link'
      step 'Choose "question by question"'
      step 'Click on "start grading"'

      purpose 'I can download student attachment' do
        step 'I see a link to download composition attachment "my_response.pdf" labeled with the file name'
      end

      purpose 'I can upload a feedback file' do
        step 'Click on the "upload file" button'
        step 'Upload a file named "feedback.pdf"'
        step 'I see the message "Your file has been successfully added. You must '
             'still click done to complete grading."'
      end

      purpose 'I can replace the feedback file' do
        step 'Click on the "replace file" button'
        step 'Upload a file named "feedback2.pdf"'
      end

      purpose 'I can remove a feedback file' do
        step 'Click on the "remove file" link'
        step 'I see an alert with the message "Are you sure you want to remove feedback2.pdf?"'
        step 'Accept the alert'
        step 'I see the message "Your file has been successfully removed."'
        step 'I give a score of 100%'
        step 'Click the "done" button'
      end
    end

    purpose 'I can give feedback to an autograded question from review student work in the gradebook' do
      step 'Visit the gradebook page'
      step 'I click on the "student 1" link'
      step 'Click on the "pending" link in the score column'
      step 'Check on the "Comment boxes" checkbox'
      step 'Write a comment for question 1 - 1'
      step 'I give a score of 8 points for question 1'
      step 'Press the "done" button'
    end

    purpose 'I can grade multi-type activity after leaving feedback' do
      step 'Visit the grading tasks assignment page'
      step 'Click on "multitype_activity" link'
      step 'Choose "question by question"'
      step 'Uncheck "Show auto-graded questions?"'
      step 'Click on "start grading"'
      step 'I see question 2 - 1'
    end

    purpose 'I can grade multi-type activity, including auto graded questions' do
      step 'Visit the grading tasks assignment page'
      step 'Click on "multitype_activity" link'
      step 'Choose "question by question"'
      step 'Check "Show auto-graded questions?"'
      step 'Click on "start grading"'
      step 'Check on the "Comment boxes" checkbox'
      step 'I see question 1 - 1'
      step 'I see the comment I left'
      step 'I see submitted response'
      step 'I give a score of 1 point'
      step 'Click the "next" button'
      step 'I see question 1 - 2'
      step 'I see submitted response'
      step 'I give a score of 2 points'
      step 'Click the "next" button'
      step 'I see question 2 - 1'
      step 'I see the direction line of the open ended question'
      step 'I see submitted response'
      step 'I give a score of 3 points'
      step 'Click the "done" button'
    end

    purpose 'I cannot grade question by question when two versions of one activity exist' do
      step 'Click on "multiple_version_activity" link'
      step 'Choose "question by question"'
      step 'Click on "start grading"'
      step 'I see the flash message "Due to editorial improvements, different ' \
           'versions of this activity exist. You may only grade student by student."'
    end

    purpose 'QxQ grading of an assessment is unaffected if I remove questions after grading' do
      step 'setup' do
        create(:enrollment, section: assessment_section, user: student_1)
        create(:enrollment, section: assessment_section, user: student_2)
        create(:category, course: assessment_course, credit_only: false)
        give_instructor_access_to_toc(activity: assessment_activity)
        initialize_program_access_client_calls_for_instructor(instructor, assessment_program)
        log_in_as(instructor)
      end

      step 'Assign a copy of an assessment that includes instructor-graded questions' do
        visit instructor_assessments_path(assessment_program.id)
        find("#copy_assessment_link_#{assessment_activity.id}").click
        find("#activity_#{Activity.last.id}_checkbox").click
        find('#set_date_link').click
        find('div[data-container="current_due_time"] a').click
        select '11', from: 'due_time_hour'
        select '59', from: 'due_time_min'
        find('input[value="save"]').click

        visit instructor_assessments_path(assessment_program.id)
        find("#release_hide_link_#{Activity.last.id}").click
      end

      step 'As student 1, complete assessment' do
        initialize_program_access_client_calls_for_user_and_program(student_1, assessment_program)
        give_user_access_to_program(student_1, assessment_program)
        log_in_as(student_1)
        visit course_section_path(assessment_course, assessment_section)
        find('.test-start-button').click
        click_on('Start the assessment')

        find('#question_01_choice_01').click
        (2..4).each do |qnumber|
          fill_in "question_#{sprintf('%02d', qnumber)}", with: 'asdf'
        end

        find('#_activity_submit').click
      end

      step 'As student 2, complete assessment' do
        initialize_program_access_client_calls_for_user_and_program(student_2, assessment_program)
        give_user_access_to_program(student_2, assessment_program)
        log_in_as(student_2)
        visit course_section_path(assessment_course, assessment_section)
        find('.test-start-button').click
        click_on('Start the assessment')

        find('#question_01_choice_01').click
        (2..4).each do |qnumber|
          fill_in "question_#{sprintf('%02d', qnumber)}", with: 'asdf'
        end

        find('#_activity_submit').click
      end

      step 'As the instructor, delete one of the the instructor-graded questions' do
        initialize_program_access_client_calls_for_instructor(instructor, assessment_program)
        log_in_as(instructor)
        visit instructor_dashboard_path(assessment_program.id)
        visit instructor_assessments_path(assessment_program.id)
        find("#edit_activity_link_#{Activity.last.id}").click
        find_all('a[aria-label="Remove section"]')[1].click
        click_on('delete')
        click_on('Save')
      end

      step 'As the instructor, grade the assessment in QxQ view' do
        click_on('Grades')
        click_on('Grading')
        find('a[data-js-task="upcoming_grading_section"]').click
        click_on(assessment_activity.title)
        find('#instructor_grading_style_question_by_question').click
        allow_any_instance_of(ResultsApiDatastore::MultipleAttempts).to receive(:stored_response)
        click_on('start grading')

        (2..3).each do |qnumber|
          fill_in "score_for_question_#{sprintf('%02d', qnumber)}_student_#{student_1.id}", with: '9'
          fill_in "score_for_question_#{sprintf('%02d', qnumber)}_student_#{student_2.id}", with: '9'
          # FIXME: sleep is bad.
          sleep 1
          find('input[type="submit"][value="Next"]').click
        end

        fill_in "score_for_question_04_student_#{student_1.id}", with: '9'
        fill_in "score_for_question_04_student_#{student_2.id}", with: '9'
        # FIXME: sleep is bad.
        sleep 1
        find('input[type="submit"][value="Done"]').click
      end

      step 'Confirm that grades are as expected' do
        click_on('Grades')
        click_on('Gradebook')
        select 'Lesson 1', from: 'all_lesson_or_week'
        [student_1, student_2].each do |student|
          # expected score is 27 point earned / 32 points possible, or 84.4% rounded to nearest 0.1%.
          expect(find("td.test-user_#{student.id}_grade_#{Activity.last.id}")).to have_text('84.4')
        end
      end
    end
  end

  scenario 'As an instructor I can grade an activity student by student' do
    purpose 'setup database' do
      step 'Create a student named "student 1"'
      step 'Create a student named "student 2"'
      step 'Create a student named "student 3"'

      step '"student 2" has a pior enrollment'

      step 'Create an open ended activity "open_ended_activity" with 4 questions'
      step '"student 1" has completed "open_ended_activity", leaving an empty response for question 2'
      step '"student 2" has completed "open_ended_activity"'
      step '"student 3" has viewed "open_ended_activity" without submitting it'

      step 'Create a composition activity "composition_activity" with 1 question'
      step '"student 1" has completed "composition_activity" and has uploaded an attachment named "my_response.pdf"'

      step 'Create a multi-type activity "multitype_activity" with 2 auto graded questions and ' \
           '1 open ended question'
      step '"student 1" has completed "multitype_activity"'

      step 'Create an activity "multiple_version_activity" with multiple versions'
      step '"student 1" has completed "multiple_version_activity"'

      step 'Create a recording_v2 activity "recording_v2_activity"'
      step '"student 1" has completed "recording_v2_activity"'

      step 'Create a vchat activity "vchat_activity"'
      step '"student 1" has completed "vchat_activity"'
    end
    step 'Log in as an instructor'

    purpose 'I can grade an activity student by student' do
      step 'Visit the grading tasks assignment page'
      step 'I see "6" assignment in the "Needs grading" section'
      step 'I see "0" assignment in the "Already graded" section'
      step 'I see "2 to be graded" next to "open_ended_activity"'
      step 'Click on "open_ended_activity" link'
      step 'Choose "student by student"'
      step 'Click on "start grading"'
      step 'I see a "view Activity" link'

      purpose 'Student shows up in the grading set' do
        step 'I see "student 1" in the student dropdown'
      end

      purpose 'Student that was in a prior section in the same program shows up in the grading set' do
        step 'I see "student 2" in the student dropdown'
      end

      purpose 'Students who have score records, but no attempts, do not show up in the grading set' do
        step 'I do not see "student 3" in the student dropdown'
      end

      purpose 'I see all the questions' do
        step 'I see the question 1 prompt'
        step 'I see the question 2 prompt'
        step 'I see the question 3 prompt'
        step 'I see the question 4 prompt'
      end

      purpose 'I see the submitted responses of "student 1" for each question' do
        step 'I see the submitted response for question 1 without extra lines'
        step 'I see "No student response" for question 2'
        step 'I see the submitted response for question 3'
        step 'I see the submitted response for question 4'
      end

      purpose 'I can write or record a comment for each question' do
        step 'I do not see a textarea to write a comment'
        step 'I do not see a button to record a comment'
        step 'Check on the "Comment boxes" checkbox'
        step 'I see a textarea to write a comment for each question'
        step 'I see a "record" button to record a comment for each question'
        step 'Write a comment for question 1'
      end

      purpose 'I can edit answer inline' do
        step "Add text to the question 1's response"
        step "Mark the question 1's response as 'should be deleted'" \
             '(by highlighting and hitting the backspace button)'
      end

      purpose 'I cannot edit answer inline when the student did not submit a response' do
        step "I cannot add text the question 2's response"
        step "I cannot mark the question 2's response as 'should be deleted'"
      end

      purpose 'I do not need to give a score to all questions' do
        step 'I see a full credit scoring button'
        step 'I see a zero credit button'
        step 'I give a score of 8 points to question 1'
        step 'I give no score to question 2'
        step 'I give a score of 7 points for question 3'
        step 'I give a score of 5 points for question 4'
        step 'Click the "next" button'
        step 'I see an alert with the message "You did not enter a grade for 1 question. OK to proceed?"'
        step 'Accept the alert'
      end

      purpose 'I grade the activity' do
        step 'I see "student 2" selected in the questions dropdown'
        step 'I give a score of 1 point for question 1'
        step 'I give a score of 7 points for question 2'
        step 'I give a score of 6 points for question 3'
        step 'I give a score of 5 points for question 4'
        step 'Click the "done" button'
        step 'I see the flash message "open_ended_activity has been successfully graded."'
      end
    end

    purpose 'I can restart a partially completed grading set' do
      step 'I see "1 to be graded"'
      step 'Click on "open_ended_activity" link'
      step 'Choose "student by student"'
      step 'Click on "start grading"'
      step 'I see student 2 graded in the student names dropdown'
    end

    purpose 'My comments are saved' do
      step 'I see the comment I left for question 1'
    end

    purpose 'My inline edit of the answer are saved' do
      step "I see the text I added to question 1's response"
      step "I see what I maked as 'should be deleted' in question 1's response"
    end

    purpose 'My scores are saved' do
      step 'I see a score of 8 points for question 1'
      step 'I see no score for question 2'
      step 'I see a score of 7 points for question 3'
      step 'I see a score of 5 points for question 4'
    end

    step 'I finish grading student 1' do
      step 'I give a score of 6 points for question 2'
    end

    purpose 'I can navigate from student to student' do
      step 'I see student 1 responses'
      step 'Click the "next" button'
      step 'I see student 2 responses'
      step 'Click the "previous" button'
      step 'I see student 1 responses'
      step 'Select "student 2" in the student names dropdown'
      step 'I see student 2 responses'
      step 'Click the "done" button'
      step 'I see the flash message "open_ended_activity has been successfully graded."'
    end

    purpose 'Graded activities are moved from Needs Grading to Already Graded' do
      step 'I see "5" assignments in the "Needs grading" section'
      step 'I see "1" assignment in the "Already graded" section'
    end

    purpose 'When grading an activity I see the changes in the gradebook' do
      step 'Visit the gradebook page'
      step 'I click on the "student 1" link'
      step 'I see a cumulative score of 65%'
      step 'Click on the "score" link'
      step 'I see "65%" in the score column'
      step 'I see "26.0" in the "points earned" column'
      step 'I see "40.0" in the "points possible" column'
    end

    purpose 'I can grade composition activity' do
      step 'Visit the grading tasks assignment page'
      purpose 'I can download student attachment' do
        step 'Click on "composition_activity" link'
        step 'Choose "student by student"'
        step 'Click on "start grading"'
        step 'I see a link to download composition attachment "my_response.pdf" labeled with the file name'
      end

      purpose 'I can upload a feedback file' do
        step 'Click on the "upload file" button'
        step 'Upload a file named "feedback.pdf"'
        step 'I see the message "Your file has been successfully added. You must '
             'still click done to complete grading."'
      end

      purpose 'I can replace the feedback file' do
        step 'Click on the "replace file" button'
        step 'Upload a file named "feedback2.pdf"'
      end

      purpose 'I can remove a feedback file' do
        step 'Click on the "remove file" link'
        step 'I see an alert with the message "Are you sure you want to remove feedback2.pdf?"'
        step 'Accept the alert'
        step 'I see the message "Your file has been successfully removed."'
        step 'I give a score of 100%'
        step 'Click the "done" button'
      end
    end

    purpose 'I can grade multi-type activity' do
      step 'Click on "multitype_activity" link'
      step 'Choose "student by student"'
      step 'Uncheck "Show auto-graded questions?"'
      step 'Click on "start grading"'
      step 'I see question 2 - 1'
    end

    purpose 'I can grade multi-type activity, including auto graded questions' do
      step 'Visit the grading tasks assignment page'
      step 'Click on "multitype_activity" link'
      step 'Choose "student by student"'
      step 'Check "Show auto-graded questions?"'
      step 'Click on "start grading"'
      step 'I see question 1 - 1'
      step 'I see submitted response'
      step 'I give a score of 1 point'
      step 'Click the "next" button'
      step 'I see question 1 - 2'
      step 'I see submitted response'
      step 'I give a score of 2 points'
      step 'Click the "next" button'
      step 'I see question 2 - 1'
      step 'I see the direction line of the open ended question'
      step 'I see submitted response'
      step 'I give a score of 3 points'
      step 'Click the "done" button'
    end

    purpose 'I can grade student by student when two versions of one activity exist' do
      step 'Click on "multiple_version_activity" link'
      step 'Choose "student by student"'
      step 'Click on "start grading"'
      step 'I see the question prompt that "student 1" submitted'
    end

    purpose 'I can grade ARC activity' do
      step 'Visit the grading tasks assignment page'
      step 'Click on "recording_v2_activity" link'
      step 'Choose "student by student"'
      step 'Click on "start grading"'
    end

    purpose 'Show comments is checked by default for ARC activities' do
      step 'The "comment boxes" checkbox is checked'
    end

    purpose 'I can grade vchat activity' do
      step 'Visit the grading tasks assignment page'
      step 'Click on "vchat_activity" link'
      step 'Choose "student by student"'
      step 'Click on "start grading"'
      step 'I see the edit grading set page for activity "vchat_activity"'
    end
  end

  scenario 'As an instructor I can grade an activity spotchecking student work' do
    purpose 'setup database' do
      step 'Create a student named "student 1"'
      step 'Create a student named "student 2"'
      step 'Create a student named "student 3"'
      step 'Create a student named "student 4"'

      step 'Create an open ended activity "open_ended_activity" with 4 questions'
      step '"student 1" has completed "open_ended_activity"' do
        step 'He spent 00:09 to complete the activity'
        step 'He answered "ab" question 1'
        step 'He answered "" for question 2'
        step 'He answered "cd" for question 3'
        step 'He answered "e" for question 4'
      end
      step '"student 2" has completed "open_ended_activity"' do
        step 'He spent 00:17 to complete the activity'
        step 'He answered "abcdef" for question 1'
        step 'He answered "ghijkl" for question 2'
        step 'He answered "mnopqr" for question 3'
        step 'He answered "stuvwx" for question 4'
      end
      step '"student 3" has completed "open_ended_activity"' do
        step 'He spent 00:05 to complete the activity'
        step 'He answered "a" for question 1'
        step 'He answered "b" for question 2'
        step 'He answered "c" for question 3'
        step 'He answered "" for question 4'
      end
      step '"student 4" has completed "open_ended_activity"' do
        step 'He spent 32:37 to complete the activity'
        step 'He left an empty response for question 1'
        step 'He answered "abc" for question 2'
        step 'He answered "def" for question 3'
        step 'He answered "ghi" for question 4'
      end
    end

    step 'Log in as an instructor'

    purpose 'I can grade an activity spotchecking student work' do
      step 'Visit the grading tasks assignment page'
      step 'I see "1" assignment in the "Needs grading" section'
      step 'I see "0" assignment in the "Already graded" section'
      step 'I see "4 to be graded" next to "open_ended_activity"'
      step 'Click on "open_ended_activity" link'
      step 'Choose "Spotcheck Student Work"'
      step 'Click on "start grading"'

      purpose 'By default the student selection is done randomly' do
        step 'The radio button "Random" is selected'
      end
      purpose 'I can select students randomly' do
        purpose 'I can choose the number of student to select' do
          step 'I see a dropdown with "1", "2", "3" and "All"'
          step '"All" is selected'
        end
        step 'Students are randomly ordered'
        step 'I see a line per student with some statistics' do
          step 'I see the student name'
          step 'I see the submission length'
          step 'I see the time spent'
          step 'I see the number of spotchecks'
          step 'I see the cumulative grade'
        end
      end

      purpose 'I can select students by outliers' do
        step 'Select "Outliers"'
        purpose 'I can choose the number of student to select' do
          step 'I see a dropdown with "1", "2", "3" and "All"'
          step '"All" is selected'
        end
        step 'Students are ordered by time followed by length of response' do
          step 'I see "student 4"'
          step 'I see "student 3"'
          step 'I see "student 1"'
          step 'I see "student 2"'
        end
        step 'I see a line per student with some statistics' do
          step 'I see the student name'
          step 'I see the submission length'
          step 'I see the time spent'
          step 'I see the number of spotchecks'
          step 'I see the cumulative grade'
        end
      end

      purpose 'I can manually select students' do
        step 'Select "Manual"'
        step 'Students are alphabetically ordered' do
          step 'I see "student 1"'
          step 'I see "student 2"'
          step 'I see "student 3"'
          step 'I see "student 4"'
        end
        step 'I see a line per student with some statistics' do
          step 'I see the student name'
          step 'I see the submission length'
          step 'I see the time spent'
          step 'I see the number of spotchecks'
          step 'I see the cumulative grade'
        end
        purpose 'I have to select at least one student to start grading' do
          step 'Click on the "spotcheck" button'
          step 'I see an alert with the message "Please select some students for spotchecking!"'
          step 'Accept the alert'
        end
        purpose 'I can select students' do
          step 'I see a checkbox in front of each student name'
          step 'Check the checkbox of "student 2"'
          step 'Check the checkbox of "student 4"'
        end
        purpose 'I can select all students' do
          step 'Check the checkbox "Select All"'
          step 'I see all the students selected'
        end
      end

      step 'Click on the "spotcheck" button'
      step 'I see a "view Activity" link'

      purpose 'I see all the questions' do
        step 'I see the question 1 prompt'
        step 'I see the question 2 prompt'
        step 'I see the question 3 prompt'
        step 'I see the question 4 prompt'
      end

      purpose 'I see the submitted response of "student 1" for each question' do
        step 'I see the submitted response for question 1'
        step 'I see "No student response" for question 2'
        step 'I see the submitted response for question 3'
        step 'I see the submitted response for question 4'
      end

      purpose 'I can write or record a comment for each question' do
        step 'I do not see a textarea to write a comment'
        step 'I do not see a button to record a comment'
        step 'Check on the "Comment boxes" checkbox'
        step 'I see a textarea to write a comment for each question'
        step 'I see a "record" button to record a comment for each question'
        step 'Write a comment for question 1'
      end

      purpose 'I can add corrections' do
        step 'Add a correction for question 1'
      end

      purpose 'I cannot add corrections when the student did not submit a response' do
        step 'I canot add a correction for question 2'
      end

      purpose 'I do not need to give a score to all questions' do
        step 'I see a full credit scoring button'
        step 'I see a zero credit button'
        step 'I give a score of 8 points to question 1'
        step 'I give no score to question 2'
        step 'I give a score of 7 points for question 3'
        step 'I give a score of 5 points for question 4'
        step 'Click the "next" button'
      end

      step 'I score questions from student 2' do
        step 'I see "student 2" selected in the questions dropdown'
        step 'I give a score of 1 point for question 1'
        step 'I give a score of 7 points for question 2'
        step 'I give a score of 6 points for question 3'
        step 'I give a score of 5 points for question 4'
      end

      purpose 'I can navigate from student to student' do
        step 'I see student 2 responses'
        step 'Click the "previous" button'
        step 'I see student 1 responses'
        step 'Select "student 3" in the student names dropdown'
        step 'I see student 3 responses'
        step 'Click the "next" button'
        step 'I see student 4 responses'
        step 'Select "student 4" in the student names dropdown'
      end

      purpose 'I choose not to grant 100% for all remaining ungraded student work on this assignment' do
        step 'Click the "done" button'
        step 'I see a modal'
        step 'Click on the "finish spotchecking" button'
        step 'I see the flash message "No changes were made for the activity open_ended_activity."'
      end
    end

    purpose 'I can restart a partially completed grading set' do
      step 'I see "3 to be graded"'
      step 'Click on "open_ended_activity" link'
      step 'Choose "Spotcheck Student Work"'
      step 'Click on "start grading"'
      step 'Select "Manual"'
      step 'I see "student 1", "student 3" and "student 4"'
      step 'Check the checkbox "Select All"'
      step 'Click on the "spotcheck" button'
      step 'I see student 1 responses'
    end

    purpose 'My scores are saved' do
      step 'I see a score of 8 points to question 1'
      step 'I see no score to question 2'
      step 'I see a score of 7 points for question 3'
      step 'I see a score of 5 points for question 4'
    end

    purpose 'My comments are saved' do
      step 'I see the comment I left for question 1'
    end

    purpose 'My corrections are saved' do
      step 'I see my correction for question 1'
    end

    step 'I finish grading student 1' do
      step 'I give a score of 6 points for question 2'
    end

    purpose 'I can grant 100% for all remaining ungraded student work on this assignment' do
      step 'Select "student 4" in the student names dropdown'
      step 'Click the "done" button'
      step 'I see a modal'
      step 'Check "Grant 100% for all remaining ungraded student work on this assignment"'
      step 'Add a comment'
      step 'Click on the "finish spotchecking" button'
      step 'I see the flash message "Spotchecking for the activity open_ended_activity ' \
           'was completed successfully."'
    end

    purpose 'Graded activities are moved from Needs Grading to Already Graded' do
      step 'I see "0" assignments in the "Needs grading" section'
      step 'I see "1" assignment in the "Already graded" section'
    end

    purpose 'When grading an activity I see the changes in the gradebook' do
      step 'Visit the gradebook page'
      step 'I see a cumulative grade of "65%" for student 1'
      step 'I see a cumulative grade of "47.5%" for student 2'
      step 'I see a cumulative grade of "100%" for student 3'
      step 'I see a cumulative grade of "100%" for student 4'
    end
  end
end
