# This spec is specific to smartbook grading.
# Normal cases are tested in instructor_grading_spec.rb
feature 'Instructor smartbook grading', if: DynamoConfig.use_local?,
                                        chrome: true, js: true,
                                        new_gb_sync: true,
                                        use_local_dynamodb: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include RspecJsDownloadHelpers
  include GradebookEngineHelpers
  include ActivityTest::MockSubmissions
  include InstructorGradingHelpers
  include GradebookEngineTest::PageObjects
  include SmartbookTest

  around do |example|
    # When using the 'percent_per_day' late penalty, the gradebook uses the nearest
    # number of days from now. In order to avoid any problem with the calculation
    # depending of the time the spec is run, we use a fixed time for the spec.
    now = Time.now
    Timecop.freeze(Time.new(now.year, now.month, now.day, 1, 0, 0)) do
      example.run
    end
  end

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }
  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program
    )
  end
  let(:category) { create(:category, course: course, credit_only: false) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity)  do
    create_smart_book_activity(
      program,
      lesson: lesson,
      strand_id: strand.location,
      title: 'due activity 1',
      max_attempts: 3
    )
  end
  let(:attempt) do
    create(
      :attempt_submitted,
      activity: activity,
      section: section,
      user: student,
      attempt_number: 1
    )
  end
  let!(:assignment) do
    create(
      :assignment,
      category: category,
      due_date: 2.days.ago,
      section: section,
      assignable: activity
    )
  end
  let(:activity_2)  do
    create_smart_book_activity(
      program,
      lesson: lesson,
      strand_id: strand.location,
      title: 'due activity 2'
    )
  end
  let(:attempt_2) do
    create(
      :attempt_submitted,
      activity: activity_2,
      section: section,
      user: student
    )
  end
  let!(:assignment_2) do
    create(
      :assignment,
      category: category,
      due_date: 2.days.ago,
      section: section,
      assignable: activity_2
    )
  end
  let(:activity_3)  do
    create_smart_book_activity(
      program,
      lesson: lesson,
      strand_id: strand.location,
      title: 'not due activity 1'
    )
  end
  let(:attempt_3) do
    create(
      :attempt_submitted,
      activity: activity_3,
      section: section,
      user: student,
      cms_revision_id: activity_3.cms_revision_id
    )
  end
  let!(:assignment_3) do
    create(
      :assignment,
      category: category,
      due_date: 2.days.from_now,
      section: section,
      assignable: activity_3
    )
  end
  let(:fake_submissions) { {} }
  let(:state_deleter_mock) { instance_double(Xapi::StateDeleter) }
  let(:smartbook_data) { SmartbookTest::SmartbookData.new }
  let(:auto_graded_interaction_1) { smartbook_data.question_5_multiple_choice }
  let(:auto_graded_interaction_1_response) { '1.[.]usted[,]2.[.]usted[,]4.[.]tú[,]5.[.]usted' }
  let(:auto_graded_interaction_2) { smartbook_data.question_6_matching }
  let(:auto_graded_interaction_2_response) { '1.[.]b.[,]2.[.]c.[,]3.[.]a.[,]4.[.]e.[,]5.[.]d.' }
  let(:instructor_graded_interaction_1) { smartbook_data.question_1_open_ended }
  let(:instructor_graded_interaction_1_response) { 'Me llamo Angela. Soy de Mexico.' }
  let(:instructor_graded_interaction_2) { smartbook_data.question_2_open_ended }
  let(:instructor_graded_interaction_2_response) { 'Blah blah blah.' }

  before do
    initialize_fake_submissions_client
    create(:enrollment, section: section, user: student)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
    allow(Xapi::StateDeleter).to receive(:new).and_return(state_deleter_mock)
    allow(state_deleter_mock).to receive(:delete)
  end

  def make_submission(attrs = {})
    submission_attrs = attrs.merge(
      points_pending: 0,
      pending: false,
      submission_length: nil,
      count_attempt: true,
      gradable: true,
      points_possible: activity.points_possible,
      points_earned: 0,
      submitted_at: Time.zone.now,
      time_spent: 1
    )
    submission = Gradebook::Submission.new(student, section, activity)
    submission.submit_points(submission_attrs)
  end

  def grade_interaction(interaction, points:)
    # TODO: Change this code to really grade the interaction
    # and only set partial_pending to false if *all* instructor-graded
    # interactions have been graded.
    score_action = GradebookEngine::GradebookAPI.find_score(
      activity_id: attempt.activity.id,
      section_id: attempt.section.id,
      user_id: attempt.user.id
    )
    return if score_action.blank?

    ::Gradebook::InstructorGrading.new(
      score_action,
      points,
      reset_partial_pending: true
    ).process
  end

  scenario 'As an instructor, I see the correct activities and counts of ' \
    'submissions to be graded' do
    visit instructor_grading_tasks_assignments_path(program.id)

    purpose 'When no interaction has been submitted, I do not see the activity' do
      for_instructor_grading_tasks_assignments_page do |pobject|
        expect(pobject.needs_grading_section_count).to eq('0')
        expect(pobject.upcoming_grading_section_count).to eq('0')
        expect(pobject.already_graded_section_count).to eq('0')
        expect(pobject.unassigned_activities_section_count).to eq('0')
      end
    end

    purpose 'Submissions for auto-graded interactions in a smartbook activity do not ' \
      'make the activity show up as needing grading' do
      submit_auto_graded_interaction(
        attempt: attempt,
        interaction: auto_graded_interaction_1,
        response: auto_graded_interaction_1_response,
        score: { raw: 70, min: 0, max: 100 }
      )

      visit instructor_grading_tasks_assignments_path(program.id)

      for_instructor_grading_tasks_assignments_page do |pobject|
        expect(pobject.needs_grading_section_count).to eq('0')
        expect(pobject.upcoming_grading_section_count).to eq('0')
        expect(pobject.already_graded_section_count).to eq('0')
        expect(pobject.unassigned_activities_section_count).to eq('0')
      end
    end

    purpose 'The submission of an instructor-graded interaction for a smartbook activity ' \
      'makes the activity show up as needing grading' do
      submit_instructor_graded_interaction(
        attempt: attempt,
        interaction: instructor_graded_interaction_1,
        response: instructor_graded_interaction_1_response
      )

      visit instructor_grading_tasks_assignments_path(program.id)

      for_instructor_grading_tasks_assignments_page do |pobject|
        expect(pobject.needs_grading_section_count).to eq('1')
        expect(pobject.upcoming_grading_section_count).to eq('0')
        expect(pobject.already_graded_section_count).to eq('0')
        expect(pobject.unassigned_activities_section_count).to eq('0')
      end
    end

    purpose 'When an instructor-graded interaction is graded, the smartbook activity ' \
      'shows up as already graded' do
      grade_interaction(instructor_graded_interaction_1, points: 3)

      visit instructor_grading_tasks_assignments_path(program.id)

      for_instructor_grading_tasks_assignments_page do |pobject|
        expect(pobject.needs_grading_section_count).to eq('0')
        expect(pobject.upcoming_grading_section_count).to eq('0')
        expect(pobject.already_graded_section_count).to eq('1')
        expect(pobject.unassigned_activities_section_count).to eq('0')
      end
    end

    purpose 'When a subsequent instructor-graded interaction is submitted, the ' \
      'smartbook activity does show up again as needing grading' do
      submit_instructor_graded_interaction(
        attempt: attempt,
        interaction: instructor_graded_interaction_2,
        response: instructor_graded_interaction_2_response
      )

      visit instructor_grading_tasks_assignments_path(program.id)

      for_instructor_grading_tasks_assignments_page do |pobject|
        expect(pobject.needs_grading_section_count).to eq('1')
        expect(pobject.upcoming_grading_section_count).to eq('0')
        expect(pobject.already_graded_section_count).to eq('0')
        expect(pobject.unassigned_activities_section_count).to eq('0')
      end
    end

    purpose 'When a subsequent auto-graded interaction is submitted, the smartbook activity ' \
      'does show up again as needing grading' do
      submit_auto_graded_interaction(
        attempt: attempt,
        interaction: auto_graded_interaction_2,
        response: auto_graded_interaction_2_response,
        score: { raw: 70, min: 0, max: 100 }
      )

      visit instructor_grading_tasks_assignments_path(program.id)

      for_instructor_grading_tasks_assignments_page do |pobject|
        expect(pobject.needs_grading_section_count).to eq('1')
        expect(pobject.upcoming_grading_section_count).to eq('0')
        expect(pobject.already_graded_section_count).to eq('0')
        expect(pobject.unassigned_activities_section_count).to eq('0')
      end
    end

    purpose 'When an instructor-graded interaction is graded, the smartbook activity ' \
      'shows up as already graded' do
      grade_interaction(instructor_graded_interaction_2, points: 4)

      visit instructor_grading_tasks_assignments_path(program.id)

      for_instructor_grading_tasks_assignments_page do |pobject|
        expect(pobject.needs_grading_section_count).to eq('0')
        expect(pobject.upcoming_grading_section_count).to eq('0')
        expect(pobject.already_graded_section_count).to eq('1')
        expect(pobject.unassigned_activities_section_count).to eq('0')
      end
    end
  end

  def validate_csv_scores(expected_scores)
    csv_content = last_download_content(encoding: 'windows-1252:utf-8')

    CSV.parse(csv_content, headers: true).each do |row|
      expected_scores.each do |activity, score|
        cell_contents = row.fetch(activity.title)
        if score == :pending
          expect(cell_contents).to eq('Pending')
        else
          expect(cell_contents).to eq("#{(score * 100).to_f.round(1)}%")
        end
      end
    end
  end

  scenario 'As an instructor, I see partial pending activities in the gradebook',
           downloads: true, retry: 3 do

    purpose 'I see all the activities correctly graded' do
      visit activities_for_lesson_url

      purpose 'I see due activities with no interaction submitted' do
        expect(column_header(activity)).to have_text(activity.title)
        expect(column_header(activity_2)).to have_text(activity_2.title)

        step 'The activities are marked as not submitted' do
          expect_cell(student.id, activity.id, submitted: false)
          expect_cell(student.id, activity_2.id, submitted: false)
        end
      end

      purpose 'I see not due activity with no interaction submitted' do
        expect(column_header(activity_3)).to have_text(activity_3.title)
        expect_cell(student.id, activity_3.id)
      end
    end

    purpose 'The gradebook is correctly exported' do
      enable_headless_downloads do
        click_button('Export')

        csv_content = last_download_content(encoding: 'windows-1252:utf-8')
        CSV.parse(csv_content, headers: true).each do |row|
          expect(row.fetch(activity.title)).to eq '0.0%'
          expect(row.fetch(activity_2.title)).to eq '0.0%'
          expect(row.fetch(activity_3.title)).to eq ''
        end
      end
    end

    purpose 'I see assignment details for each activities' do
      purpose 'I see assignment details for due activities with no interaction submitted' do
        for_student_grade_modal(student, activity) do |modal|
          modal.open
          expect(modal).to have_no_grade_this_assignment_link
          expect(modal).to have_no_reset_student_work_link
          expect(modal).to have_no_review_student_work_link
          expect(modal).to have_change_earned_score_link
          expect(modal).to have_accept_late_work_link
          modal.close
        end

        for_student_grade_modal(student, activity_2) do |modal|
          modal.open
          expect(modal).to have_no_grade_this_assignment_link
          expect(modal).to have_no_reset_student_work_link
          expect(modal).to have_no_review_student_work_link
          expect(modal).to have_change_earned_score_link
          expect(modal).to have_accept_late_work_link
          modal.close
        end
      end

      purpose 'I do not see a link to show assignment details for not due activity ' \
        'with no interaction submitted' do
        for_student_grade_modal(student, activity_3) do |modal|
          expect(modal).to have_no_link_to_be_opened
        end
      end
    end

    step 'Submit auto-graded interactions' do
      submit_auto_graded_interaction(
        attempt: attempt,
        interaction: auto_graded_interaction_1,
        response: auto_graded_interaction_1_response,
        score: { raw: 60, min: 0, max: 100 }
      )
      submit_auto_graded_interaction(
        attempt: attempt_3,
        interaction: auto_graded_interaction_1,
        response: auto_graded_interaction_1_response,
        score: { raw: 90, min: 0, max: 100 }
      )
    end

    # The activity has a penalty factor of .9 (2 days late and a penalty of 5% per day
    activity_penalty_factor = 0.9
    activity_score = ((0.60 * auto_graded_interaction_1.points_possible) / activity.points_possible) * activity_penalty_factor
    activity_2_score = 0.0
    activity_3_score = (0.90 * auto_graded_interaction_1.points_possible) / activity_3.points_possible

    purpose 'I see all the activities correctly graded' do
      visit activities_for_lesson_url

      purpose 'I see due activity with an auto graded interaction submitted' do
        expect(column_header(activity)).to have_text(activity.title)

        step 'The activity has a score and is marked as late' do
          expect_cell(
            student.id, activity.id,
            percent: (activity_score * 100).round(1),
            points: (activity_score * activity_3.points_possible).round(1),
            late: true
          )
        end
      end

      purpose 'I see due activity with no interaction submitted' do
        expect(column_header(activity_2)).to have_text(activity_2.title)
        expect_cell(student.id, activity_2.id, submitted: false)
      end

      purpose 'I see not due activity with an auto graded interaction submitted' do
        expect(column_header(activity_3)).to have_text(activity_3.title)

        step 'The activity has a score and is not marked as late' do
          expect_cell(
            student.id, activity_3.id,
            percent: (activity_3_score * 100).round(1),
            points: (activity_3_score * activity_3.points_possible).round(1),
            late: false
          )
        end
      end
    end

    purpose 'The gradebook is correctly exported' do
      enable_headless_downloads do
        click_button('Export')

        validate_csv_scores(
          activity => activity_score,
          activity_2 => 0,
          activity_3 => activity_3_score
        )
      end
    end

    purpose 'I see assignment details for each activities' do
      for_student_grade_modal(student, activity) do |modal|
        modal.open
        expect(modal).to have_no_grade_this_assignment_link
        expect(modal).to have_reset_student_work_link
        expect(modal).to have_review_student_work_link
        expect(modal).to have_change_earned_score_link
        expect(modal).to have_accept_late_work_link
        # Points possible should be as expected.
        expect(page).to have_content('1 of 12 Complete')
        modal.close
      end

      for_student_grade_modal(student, activity_2) do |modal|
        modal.open
        expect(modal).to have_no_grade_this_assignment_link
        expect(modal).to have_no_reset_student_work_link
        expect(modal).to have_no_review_student_work_link
        expect(modal).to have_change_earned_score_link
        expect(modal).to have_accept_late_work_link
        modal.close
      end

      for_student_grade_modal(student, activity_3) do |modal|
        modal.open
        expect(modal).to have_no_grade_this_assignment_link
        expect(modal).to have_reset_student_work_link
        expect(modal).to have_review_student_work_link
        expect(modal).to have_no_change_earned_score_link
        expect(modal).to have_no_accept_late_work_link
        modal.close
      end
    end

    step 'Submit instructor-graded interactions' do
      [attempt, attempt_2, attempt_3].each do |attempt|
        submit_instructor_graded_interaction(
          attempt: attempt,
          interaction: instructor_graded_interaction_1,
          response: instructor_graded_interaction_1_response
        )
      end
    end

    activity_score = ((0.60 * auto_graded_interaction_1.points_possible) / (activity.points_possible - instructor_graded_interaction_1.points_possible)) * activity_penalty_factor
    activity_3_score = (0.90 * auto_graded_interaction_1.points_possible) / (activity_3.points_possible - instructor_graded_interaction_1.points_possible)

    purpose 'I see all the activities correctly graded' do
      visit activities_for_lesson_url

      purpose 'I see due activity with a not graded instructor-graded interaction submitted' do
        expect(column_header(activity)).to have_text(activity.title)

        step 'The activity has a score and is marked as late and partial pending' do
          expect_cell(
            student.id, activity.id,
            points: (activity_score * activity.points_possible).round(1),
            late: true,
            partial_pending: true
          )
        end
      end

      purpose 'I see due activity with only an instructor-graded interaction submitted' do
        expect(column_header(activity_2)).to have_text(activity_2.title)

        step 'The activity has a score of 0 and is marked as late and partial pending' do
          expect_cell(
            student.id, activity_2.id,
            percent: (activity_2_score * 100).round(1),
            points: (activity_2_score * activity_2.points_possible).round(1),
            late: true,
            partial_pending: true
          )
        end
      end

      purpose 'I see the not due activity with a not graded instructor-graded interaction submitted' do
        expect(column_header(activity_3)).to have_text(activity_3.title)

        step 'The activity has a score, is marked as partial pending and is not marked as late' do
          expect_cell(
            student.id, activity_3.id,
            points: (activity_3_score * activity_3.points_possible).round(1),
            late: false,
            partial_pending: true
          )
        end
      end
    end

    purpose 'The gradebook is correctly exported' do
      enable_headless_downloads do
        click_button('Export')

        validate_csv_scores(
          activity => :pending,
          activity_2 => :pending,
          activity_3 => :pending
        )
      end
    end

    purpose 'I see assignment details for each activities' do
      for_student_grade_modal(student, activity) do |modal|
        modal.open
        expect(modal).to have_grade_this_assignment_link
        expect(modal).to have_reset_student_work_link
        expect(modal).to have_review_student_work_link
        expect(modal).to have_change_earned_score_link
        expect(modal).to have_accept_late_work_link
        modal.close
      end

      for_student_grade_modal(student, activity_2) do |modal|
        modal.open
        expect(modal).to have_grade_this_assignment_link
        expect(modal).to have_reset_student_work_link
        expect(modal).to have_review_student_work_link
        expect(modal).to have_change_earned_score_link
        expect(modal).to have_accept_late_work_link
        modal.close
      end
      for_student_grade_modal(student, activity_3) do |modal|
        modal.open
        expect(modal).to have_grade_this_assignment_link
        expect(modal).to have_reset_student_work_link
        expect(modal).to have_review_student_work_link
        expect(modal).to have_no_change_earned_score_link
        expect(modal).to have_no_accept_late_work_link
        modal.close
      end
    end

    grade_interaction(instructor_graded_interaction_1, points: 3)
    visit activities_for_lesson_url

    purpose 'I see assignment details for each activities' do
      for_student_grade_modal(student, activity) do |modal|
        modal.open
        expect(modal).to have_no_grade_this_assignment_link
        expect(modal).to have_reset_student_work_link
        expect(modal).to have_review_student_work_link
        expect(modal).to have_change_earned_score_link
        expect(modal).to have_accept_late_work_link
        modal.close
      end

      for_student_grade_modal(student, activity_2) do |modal|
        modal.open
        expect(modal).to have_grade_this_assignment_link
        expect(modal).to have_reset_student_work_link
        expect(modal).to have_review_student_work_link
        expect(modal).to have_change_earned_score_link
        expect(modal).to have_accept_late_work_link
        modal.close
      end
      for_student_grade_modal(student, activity_3) do |modal|
        modal.open
        expect(modal).to have_grade_this_assignment_link
        expect(modal).to have_reset_student_work_link
        expect(modal).to have_review_student_work_link
        expect(modal).to have_no_change_earned_score_link
        expect(modal).to have_no_accept_late_work_link
        modal.close
      end
    end
  end

  scenario 'As an instructor, I see partial pending activities in the gradebook user overview' do
    visit gradebook_engine.section_user_overview_path(program, section, student)

    purpose 'I see all the activities correctly graded' do
      click_link('Scores')

      purpose 'I see due activities with no interaction submitted' do
        expect_student_score_cell(
          student.id, activity.id,
          points_possible: activity.points_possible,
          status: 'Not Submitted'
        )
        expect_student_score_cell(
          student.id, activity_2.id,
          points_possible: activity_2.points_possible,
          status: 'Not Submitted'
        )
      end

      purpose 'I see not due activity with no interaction submitted' do
        expect_student_score_cell(
          student.id, activity_3.id,
          points_possible: activity_3.points_possible,
          status: 'Not Submitted'
        )
      end
    end

    step 'Submit auto-graded interactions' do
      submit_auto_graded_interaction(
        attempt: attempt,
        interaction: auto_graded_interaction_1,
        response: auto_graded_interaction_1_response,
        score: { raw: 80, min: 0, max: 100 }
      )
      submit_auto_graded_interaction(
        attempt: attempt_3,
        interaction: auto_graded_interaction_1,
        response: auto_graded_interaction_1_response,
        score: { raw: 27, min: 0, max: 100 }
      )
    end

    # The activity has a penalty factor of .9 (2 days late and a penalty of 5% per day
    activity_penalty_factor = 0.9
    activity_points_earned = 0.80 * auto_graded_interaction_1.points_possible
    activity_2_points_earned = 0.0
    activity_3_points_earned = 0.27 * auto_graded_interaction_1.points_possible

    visit gradebook_engine.section_user_overview_path(program, section, student)

    purpose 'I see all the activities correctly graded' do
      click_link('Scores')

      purpose 'I see due activity with an auto graded interaction submitted' do
        step 'The activity has a score and is marked as late' do
          points = activity_points_earned * activity_penalty_factor
          expect_student_score_cell(
            student.id, activity.id,
            score: (points * 100 / activity.points_possible).round(1),
            points: points.round(1),
            points_possible: activity.points_possible,
            attempts: 1,
            status: 'Late'
          )
        end
      end

      purpose 'I see due activity with no interaction submitted' do
        expect_student_score_cell(
          student.id, activity_2.id,
          points_possible: activity_2.points_possible,
          status: 'Not Submitted'
        )
      end

      purpose 'I see not due activity with an auto graded interaction submitted' do
        step 'The activity has a score and is marked as on time' do
          expect_student_score_cell(
            student.id, activity_3.id,
            score: (activity_3_points_earned * 100 / activity_3.points_possible).round(1),
            points: activity_3_points_earned.round(1),
            points_possible: activity_3.points_possible,
            attempts: 1,
            status: 'On Time'
          )
        end
      end
    end

    step 'Submit instructor-graded interactions' do
      [attempt, attempt_3].each do |attempt|
        submit_instructor_graded_interaction(
          attempt: attempt,
          interaction: instructor_graded_interaction_1,
          response: instructor_graded_interaction_1_response
        )
      end
    end

    activity_points_earned = (((0.80 * auto_graded_interaction_1.points_possible) / (activity.points_possible - instructor_graded_interaction_1.points_possible)) * activity.points_possible).round(2)
    activity_3_points_earned = (((0.27 * auto_graded_interaction_1.points_possible) / (activity_3.points_possible - instructor_graded_interaction_1.points_possible)) * activity_3.points_possible).round(2)

    visit gradebook_engine.section_user_overview_path(program, section, student)

    purpose 'I see all the activities correctly graded' do
      click_link('Scores')

      purpose 'I see due activity with a not graded instructor-graded interaction submitted' do
        step 'The activity has a score and is marked as late and partial pending' do
          points = activity_points_earned * activity_penalty_factor
          expect_student_score_cell(
            student.id, activity.id,
            points: points.round(1),
            points_possible: activity.points_possible,
            attempts: 1,
            status: 'Late',
            partial_pending: true
          )
        end
      end

      purpose 'I see due activity with no interaction submitted' do
        expect_student_score_cell(
          student.id, activity_2.id,
          points_possible: activity_2.points_possible,
          status: 'Not Submitted'
        )
      end

      purpose 'I see the not due activity with a not graded instructor-graded interaction submitted' do
        step 'The activity has a score, is marked as partial pending and is marked as on time' do
          expect_student_score_cell(
            student.id, activity_3.id,
            score: (activity_3_points_earned * 100 / activity_3.points_possible).round(1),
            points: activity_3_points_earned.round(1),
            points_possible: activity_3.points_possible,
            attempts: 1,
            status: 'On Time',
            partial_pending: true
          )
        end
      end
    end
  end

  scenario 'As an instructor, I can reset the work of a single student' do
    step 'Submit auto and instructor-graded interactions' do
      submit_auto_graded_interaction(
        attempt: attempt_3,
        interaction: auto_graded_interaction_1,
        response: auto_graded_interaction_1_response,
        score: { raw: 70, min: 0, max: 100 }
      )
      submit_instructor_graded_interaction(
        attempt: attempt_3,
        interaction: instructor_graded_interaction_1,
        response: instructor_graded_interaction_1_response
      )
    end

    total_points_earned = (0.70 * auto_graded_interaction_1.points_possible)
    total_points_possible = activity.points_possible - instructor_graded_interaction_1.points_possible
    activity_score = total_points_earned / total_points_possible

    visit activities_for_lesson_url

    purpose 'The instructor can select the Reset Work Link' do
      for_student_grade_modal(student, activity_3) do |modal|
        modal.open
        click_link('Reset Student Work')
      end
    end

    purpose 'The instructor can cancel reset student work' do
      for_student_grade_modal(student, activity_3) do |modal|
        click_button('Cancel')
        # student score remains the same
        expect_cell(
          student.id, activity_3.id,
          points: (activity_score * activity.points_possible).round(1),
          late: false,
          partial_pending: true
        )
      end
    end

    purpose 'The instructor can reset work for a single student' do
      for_student_grade_modal(student, activity_3) do |modal|
        click_link('Reset Student Work')
        find('.test-reset').click

        Timeout.timeout(Capybara.default_max_wait_time) do
          loop until page.has_no_selector?('h3', text: 'Reset Student Work')
        end

        # zero points_earned and an adjusted score
        expect(
          ::GradebookEngine::CurrentScoreAction.where(
            user_id: student.id, activity_id: activity_3.id
          ).first.summation
        ).to eql(
          'points_earned' => 0,
          'points_possible' => activity.points_possible,
          'adjusted' => true
        )
      end
    end
  end
end
