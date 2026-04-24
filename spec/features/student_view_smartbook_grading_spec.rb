# coding: utf-8
feature 'Instructor smartbook grading', if: DynamoConfig.use_local?,
        chrome: true, js: true, new_gb_sync: true, use_local_dynamodb: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include RspecJsDownloadHelpers
  include GradebookEngineHelpers
  include ActivityTest::MockSubmissions
  include InstructorGradingHelpers
  include GradebookEngineTest::PageObjects
  include CapybaraViewHelpers
  include SmartbookTest

  around do |example|
    # When using the 'percent_per_day' late penalty, the gradebook uses the nearest
    # number of days from now. In order to avoid any problem with the calculation
    # depending of the time the spec is run, we use a fixed date for the spec.
    now = Time.now
    Timecop.freeze(Time.new(now.year, now.month, now.day, 1, 0, 0)) do
      example.run
    end
  end

  before do
    # Drop the table and recreate it in between each spec.
    Xapi::Statement.migrate_down
    Xapi::Statement.migrate_up
  end

  let(:smartbook_recording_endpoint) { Rails.application.config.smartbook_recording_endpoint }
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
      start_date: -1.days.from_now,
      program: program
    )
  end
  let(:category) { create(:category, course: course, credit_only: false) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity)  do
    create_smart_book_activity(
      program,
      grading_method: 'auto',
      lesson: lesson,
      strand_id: strand.location
    )
  end
  let(:attempt) do
    create(
      :attempt_submitted,
      activity: activity,
      section: section,
      user: student,
      cms_revision_id: activity.cms_revision_id
    )
  end
  let!(:assignment) do
    create(
      :assignment,
      category: category,
      due_date: Date.today + 2,
      section: section,
      assignable: activity
    )
  end

  let(:fake_submissions) { {} }
  let(:smartbook_data) { SmartbookTest::SmartbookData.new }
  let(:question_1) { smartbook_data.question_1_open_ended }
  let(:question_2) { smartbook_data.question_2_open_ended }
  let(:question_4) { smartbook_data.question_4_audio_recording }
  let(:question_5) { smartbook_data.question_5_multiple_choice }
  let(:question_1_instructor_graded) { question_1 }
  let(:question_2_instructor_graded) { question_2 }
  let(:question_4_audio_recording) { question_4 }
  let(:question_5_auto_graded) { question_5 }
  let(:student_question_1_response) do
    'Me llamo Angela. Soy de Mexico.'
  end
  let(:student_question_2_response) do
    'Blah blah blah.'
  end
  let(:student_question_4_audio_filename) do
    'VR_SBHS1/HS1UP002bCCP1/201926392937868.wav'
  end
  let(:student_question_4_response) do
    "#{smartbook_recording_endpoint}/#{section.guid}/" \
    "lossless_user_token/#{student_question_4_audio_filename}"
  end
  let(:student_question_5_response) do
    '1.[.]usted[,]2.[.]usted[,]4.[.]tú[,]5.[.]usted'
  end
  let(:question_comment_display) do
    {
      question_1.label => true,
      question_2.label => false,
      question_3.label => true,
      question_4.label => true
    }
  end

  RSpec::Matchers.define :not_exist do
    match(&:not_exist?)
  end

  before do
    initialize_fake_submissions_client
    create(:enrollment, section: section, user: student)

    submit_instructor_graded_interaction(
      attempt: attempt,
      interaction: question_1_instructor_graded,
      response: student_question_1_response
    )
    submit_instructor_graded_interaction(
      attempt: attempt,
      interaction: question_2_instructor_graded,
      response: student_question_2_response
    )
    submit_instructor_graded_interaction(
      attempt: attempt,
      interaction: question_4_audio_recording,
      response: student_question_4_response
    )
    submit_auto_graded_interaction(
      attempt: attempt,
      interaction: question_5_auto_graded,
      response: student_question_5_response,
      score: { raw: 70, min: 0, max: 100 }
    )
    create_gradebook_engine_submission(
      activity: activity,
      pending: false,
      partial_pending: true,
      points_earned: 60.0,
      section: section,
      submitted_at: 3.days.ago.to_date,
      student: student,
      time_spent: 3_600
    )
  end

  before do
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)

    stub_request(:get, /#{Rails.application.config.lossless_base_url}.*/)
      .to_return(
        status: 200,
        body: { token: '1234-4568' }.to_json
      )
  end

  scenario 'I can review instructor feedback', test_debt: true do
    visit section_activity_path(section.id, activity)

    purpose 'No instructor feedback so Instructor Feedback link not shown' do
      expect(page).to have_no_selector('.test-slide-feedback', visible: true)
    end
    attempt.reload
    FeedbackItem.submit(:student => attempt.student,
                        :section => attempt.section,
                        :activity => attempt.activity,
                        :attempt => attempt,
                        :question_label => question_1.label,
                        :comment => 'You can do better',
                        :current_user => student)

    # recorded comment
    FeedbackItem.submit(:student => attempt.student,
                        :section => attempt.section,
                        :activity => attempt.activity,
                        :attempt => attempt,
                        :question_label => question_2.label,
                        :points_earned => 6.5,
                        :recording_path => '/24af249b/e351/24af249b-e351-4fb1-8f07-1579c7e47af9_2',
                        :current_user => student)

    FeedbackItem.submit(:student => attempt.student,
                        :section => attempt.section,
                        :activity => attempt.activity,
                        :attempt => attempt,
                        :question_label => question_4.label,
                        :points_earned => 9.0,
                        :comment => 'Nice work!',
                        :current_user => student)

    # auto-graded points override
    FeedbackItem.submit(:student => attempt.student,
                        :section => attempt.section,
                        :activity => attempt.activity,
                        :attempt => attempt,
                        :comment => 'This was a confusing question, but I think you could do better.',
                        :question_label => question_5.label,
                        :current_user => student)

    attempt.feedback_items.reload
    visit section_activity_path(section.id, activity)

    purpose 'Instructor feedback displayed on slide out panel' do
      click_link('Instructor Feedback')

      # feedback for Q 1
      expect(page).to have_link('Question 1')
      for_instructor_feedback(question_1) do |container|
        expect(container.comment).to include('You can do better')
        expect(container.score).to include('Not yet graded')
        expect(container).to have_no_audio_player
      end

      # feedback for Q 2 includes a recorded comment
      # so check for audio player display
      expect(page).to have_link('Question 2')
      for_instructor_feedback(question_2) do |container|
        expect(container.score).to include('6.5 out of 10 points')
        expect(container).to have_audio_player
      end

      # feedback for Q 4 - voice recording
      expect(page).to have_link('Question 4')
      for_instructor_feedback(question_4) do |container|
        expect(container.comment).to include('Nice work!')
        expect(container.score).to include('9.0 out of 10 points')
        expect(container).to have_no_audio_player
      end

      # ensure that all the feedback items display,
      # including auto-graded grade overrides
      expect(page).to have_link('Question 5a')
      for_instructor_feedback(question_5) do |container|
        expect(container.comment).to include('This was a confusing question, but I think you could do better.')
        expect(container).to have_no_audio_player
      end
    end

    purpose 'Selecting link closes panel' do
      click_link('Instructor Feedback')
      expect(page).to have_no_selector('.test-slide-toggle-label-open', visible: true)
    end

    # When leaving the smartbook activity page, the page sends a
    # statement write request that can be received after the database cleanup.
    # To ensure this does not occur, we visit another page before ending the spec.
    visit course_section_path(course, section)
  end
end
