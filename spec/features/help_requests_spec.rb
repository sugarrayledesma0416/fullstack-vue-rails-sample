feature 'Help requests',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:activity) { create_multiple_choice_activity(program) }
  let(:svr_activity) { create_solo_video_recording_activity(program) }
  let(:section) { create(:section, course:, instructor:) }
  let(:solo_video_recording) { SoloVideoRecording.new }

  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program:
    )
  end

  let(:attempt_results) do
    # The student left everything blank so they got 0 points.
    MaestroActivityEngine::ActivityContent::Results
      .new(activity.content_object).tap do |results|
      results.add(label: 'question_01', response: '')
      results.add(label: 'question_02', response: '')
      results.add(label: 'question_03', response: '')
      results.add(label: 'question_04', response: '')
    end
  end

  let(:svr_attempt_results) do
    MaestroActivityEngine::ActivityContent::Results.new(
      activity.content_object
    ).tap do |results|
      results.add(
        auto_graded: false,
        correctness: 'pending',
        label: 'question_01',
        points_earned: 0,
        points_possible: 10,
        submitted: true,
        response: solo_video_recording
      )
    end
  end

  before do
    create(:enrollment, section:, user: student)
    initialize_program_access_client_calls_for_instructor(instructor, program)
  end

  scenario 'As an instructor, I can see a score review request and ' \
           'access the review work page for that request' do
    allow_any_instance_of(Attempt).to receive(:results) { attempt_results }
    log_in_as(instructor)
    create_gradebook_engine_submission(submitted_at: 5.days.ago)
    create(:attempt_completed, activity:, section:, user: student)

    # Create a review request, attach it to one of the questions.
    student_comment = "I didn't understand the question."
    create(
      :review_request,
      activity:,
      helpable_item_type: 'whole_question',
      helpable_item_id: 'question_01_whole_question',
      instructor_comment: nil,
      program:,
      section:,
      student_comment:,
      user: student
    )

    # Go to the help request index page.
    visit instructor_help_requests_path(program.id)

    step 'I should see the pending review request count as 1' do
      expect(find('#unprocessed_review_request_count.circled')).to have_text('1')
    end

    step 'I can click the unprocessed score reviews list' do
      find('#unprocessed_review_request_header a').click
    end

    step 'I should see the title of activity for which the score review was requested' do
      expect(
        all('[data-content-type=activity_title]').map(&:text)
      ).to eq([activity.title])
    end

    step 'I should see the student name who submitted the score review request' do
      expect(all('.student_name_link').map(&:text)).to eq([student.full_name])
    end

    step 'I click the student name link' do
      click_link(student.full_name)
    end

    step 'I should see the review request details for the question' do
      within('#question_01') do
        expect(find('.test-student-name')).to have_text(student.full_name)
        expect(find('.test-student-comment-text')).to have_text(student_comment)
      end
    end
  end

  scenario 'As an instructor, I can see a score review request for solo video ' \
           'recording and access the review work page for that request' do
    allow_any_instance_of(Attempt).to receive(:results) { svr_attempt_results }
    log_in_as(instructor)
    create_gradebook_engine_submission(
      activity: svr_activity,
      section:,
      student:,
      submitted_at: 5.days.ago
    )
    create(:attempt_completed, activity: svr_activity, section:, user: student)

    # Create a review request, attach it to one of the question of SVR.
    student_comment = "I didn't understand the question of solo video recording."
    create(
      :review_request,
      activity: svr_activity,
      helpable_item_type: 'whole_question',
      helpable_item_id: 'solo_video_recording_container',
      instructor_comment: nil,
      program:,
      section:,
      student_comment:,
      user: student
    )

    # Go to the help request index page.
    visit instructor_help_requests_path(program.id)

    step 'I should see the pending review request count as 1' do
      expect(find('#unprocessed_review_request_count.circled')).to have_text('1')
    end

    step 'I can click the unprocessed score reviews list' do
      find('#unprocessed_review_request_header a').click
    end

    step 'I should see the title of activity for which the score review was requested' do
      expect(
        all('[data-content-type=activity_title]').map(&:text)
      ).to eq([svr_activity.title])
    end

    step 'I should see the student name who submitted the score review request' do
      expect(all('.student_name_link').map(&:text)).to eq([student.full_name])
    end

    step 'I click the student name link' do
      click_link(student.full_name)
    end

    step 'I should see the review request details for the question' do
      within('#question_01') do
        expect(find('.test-student-name')).to have_text(student.full_name)
        expect(find('.test-student-comment-text')).to have_text(student_comment)
      end
    end
  end
end
