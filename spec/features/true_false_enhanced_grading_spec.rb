feature 'Grading true-false enhanced activities',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers
  include GradebookEngineTest::PageObjects
  include Capybara::Angular::DSL

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:category) { create(:category, course: course, penalty_percent: 0) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  let(:concept) { activity.concept }
  let(:lesson) { activity.lesson }
  let(:strand) { activity.strand }
  let(:attempt_results) do
    MaestroActivityEngine::ActivityContent::Results.new(
      activity.content_object
    ).tap do |results|
      results.add(
        auto_graded: true,
        correctness: 'incorrect',
        label: 'question_01',
        points_earned: 0,
        points_possible: 2,
        response: '2'
      )
      results.add(
        auto_graded: true,
        label: 'question_01_correction',
        points_earned: 0,
        points_possible: 0,
        response: ''
      )
      results.add(
        auto_graded: false,
        correctness: 'pending',
        label: 'question_02',
        points_earned: 0,
        points_possible: 0,
        response: '2'
      )
      results.add(
        auto_graded: false,
        correctness: 'pending',
        label: 'question_02_correction',
        points_earned: 0,
        points_possible: 0,
        response: 'Caracas'
      )
      results.add(
        auto_graded: true,
        correctness: 'correct',
        label: 'question_03',
        points_earned: 2,
        points_possible: 2,
        response: '1'
      )
      results.add(
        auto_graded: true,
        label: 'question_03_correction',
        points_earned: 0,
        points_possible: 0,
        response: ''
      )
      results.add(
        auto_graded: false,
        correctness: 'pending',
        label: 'question_04',
        points_earned: 0,
        points_possible: 0,
        response: '2'
      )
      results.add(
        auto_graded: false,
        correctness: 'pending',
        label: 'question_04_correction',
        points_earned: 0,
        points_possible: 0,
        response: 'Lima'
      )
      results.add(
        auto_graded: true,
        correctness: 'correct',
        label: 'question_05',
        points_possible: 2,
        points_earned: 2,
        response: '1'
      )
      results.add(
        auto_graded: true,
        label: 'question_05_correction',
        points_earned: 0,
        points_possible: 0,
        response: ''
      )
    end
  end

  let(:activity) { create_true_false_enhanced_activity(program) }

  def score_field(question_label)
    find("input#score_for_#{question_label}_student_#{student_1.id}")
  end

  def set_score(question_label, score)
    element = score_field(question_label)
    # see StudentAnswerPageObject#score=
    loop do
      element.set(score)
      break if element.value == score.to_s
    end
  end

  scenario 'As an instructor, when grading true-false enhanced activities ' \
           'in spotcheck mode, the initial scores are blank, not 0.0.',
           :aggregate_failures do
    create(:enrollment, user: student_1, section: section)
    create(:enrollment, user: student_2, section: section)
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: Date.yesterday,
      section: section
    )
    create(:attempt_completed, activity: activity, section: section, user: student_1)
    create(:attempt_completed, activity: activity, section: section, user: student_2)
    create_gradebook_engine_submission(
      activity: activity,
      pending: true,
      section: section,
      student: student_1,
      submitted_at: Time.now.utc,
      time_spent: 123
    )
    create_gradebook_engine_submission(
      activity: activity,
      pending: true,
      section: section,
      student: student_2,
      submitted_at: Time.now.utc,
      time_spent: 123
    )

    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Attempt).to receive(:results) { attempt_results }
    # rubocop:enable RSpec/AnyInstance
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    # Go to the gradebook page showing activity-level scores.
    visit activities_for_lesson_url

    grade_cell = find(student_grade_selector(student_1.id))
    expect(grade_cell.text).to match(/Pending/)

    # Click the score to bring up the modal.
    grade_cell.click

    expect(find('.test-modal-content').text).to include('NOT YET GRADED')

    find('.test-modal-content a', text: 'Review Student Work').click

    # Verify that the score fields for the auto-graded questions are
    # popuplated with the correct scores, and the score fields for the
    # pending open ended questions are blank.
    expect(score_field('question_01').value).to eq('0.0')
    expect(score_field('question_02').value).to eq('')
    expect(score_field('question_03').value).to eq('2.0')
    expect(score_field('question_04').value).to eq('')
    expect(score_field('question_05').value).to eq('2.0')

    # Set a score for one of the two open-ended pending questions
    set_score('question_02', 2.0)
    submit_button = find(:css, "input.done[value='Save & Done']")
    scroll_to(submit_button)
    click_button('Done', visible: true)

    visit activities_for_lesson_url

    # Student 1 only got a score for question 2, so they should still
    # show up as pending.
    grade_cell = find(student_grade_selector(student_1.id))
    expect(grade_cell.text).to include('Pending')
    grade_cell.click
    expect(find('.test-modal-content')).to have_content('NOT YET GRADED')

    visit instructor_grading_styles_path(
      program.id,
      activity.id,
      task_type: GradingTask::NEEDS_GRADING
    )

    choose('Spotcheck Student Work')
    click_on('start grading')

    for_grading_spotcheck_student_selection do |pobject|
      pobject.spotcheck_style = :manual

      # Ensure we choose student_1, since the order of the students in the
      # manual spotcheck list isn't sorted by student id or submission date.
      pobject.manual_students.each do |row|
        row.check if row.to_s == "student_row_#{student_1.id}"
      end
      pobject.start_grading_button.click
    end

    # Verify that the score field for the graded open-ended question has
    # the score.
    expect(score_field('question_02').value).to eq('2.0')

    # Verify that the score field for the pending open-ended question is blank.
    expect(score_field('question_04').value).to eq('')

    # Set a score for the remaining pending question.
    set_score('question_04', 2.0)
    for_grading_student_by_student { |pobject| pobject.button(:done).click }

    for_grading_spotcheck_confirmation_modal do |pobject|
      # Check the checkbox to grant full-credit for pending questions to all
      # students who were not selected to be manually spotchecked.
      pobject.grant_grade
      pobject.finish_spotchecking
    end

    # Go to the gradebook page showing activity-level scores.
    visit activities_for_lesson_url

    # Student 1 should be completely graded now, and no longer show up
    # as pending. They still got one auto-graded question wrong, so they
    # get 80 % instead of 100 %.
    grade_cell = find(student_grade_selector(student_1.id))
    expect(grade_cell.text).not_to include('Pending')
    expect(grade_cell.text).to include('80.0 %')
    grade_cell.click

    modal_text = find('.test-modal-content')
    expect(modal_text).to have_no_content('NOT YET GRADED')
    expect(modal_text).to have_content('80 %')

    # Close the modal for Student 1
    find('.test-modal-close').click

    # Student 2 should have been granted full credit on the 2 pending
    # questions as specified in the finish-spotcheck dialog.
    # They should not show up as pending. They still got one auto-graded
    # question wrong, so they get 80 % instead of 100 %.
    grade_cell = find(student_grade_selector(student_2.id))
    expect(grade_cell.text).not_to include('Pending')
    expect(grade_cell.text).to include('80.0 %')
    grade_cell.click

    modal_text = find('.test-modal-content')
    expect(modal_text).to have_no_content('NOT YET GRADED')
    expect(modal_text).to have_content('80 %')

    # Verify the grade in the gradebook
    # score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
    #   student.id, section.id, activity.id
    # ).first
    # expect(score_action.points_earned.to_f).to eq(8.0)
    # expect(score_action.pending).to be_falsey

    # visit instructor_grading_styles_path(
    #   program.id,
    #   activity.id,
    #   task_type: GradingTask::NEEDS_GRADING
    # )
    #
    # choose('Student by student')
    # click_on('start grading')
    #
    # accept_confirm('You did not enter a grade for 1 question. OK to proceed?') do
    #   for_grading_student_by_student { |pobject| pobject.button(:done).click }
    # end
    #
    # # Go to the gradebook page showing activity-level scores.
    # visit activities_for_lesson_url
    #
    # grade_cell = find(student_grade_selector)
    # expect(grade_cell.text).to match(/Pending/)
    #
    # # Click the score to bring up the modal.
    # find(student_grade_selector).click
    #
    # find('.test-modal-content a', text: 'Review Student Work').click
    #
    #
    # expect(score_field('question_01').value).to eq('0.0')
    # expect(score_field('question_02').value).to eq('2.0')
    # expect(score_field('question_03').value).to eq('2.0')
    # expect(score_field('question_04').value).to eq('')
    # expect(score_field('question_05').value).to eq('2.0')
  end
end
