feature 'Grading Solo Video Recording activities',
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
  let(:course) { create(:course, owner: instructor, program: program, chat_level: 'disabled') }
  let(:category) { create(:category, course: course, penalty_percent: 0) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  let(:concept) { activity.concept }
  let(:lesson) { activity.lesson }
  let(:strand) { activity.strand }
  let(:solo_video_recording) { SoloVideoRecording.new }
  let(:attempt_results) do
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

  let(:activity) { create_solo_video_recording_activity(program) }

  let(:pnub_client_wrapper) do
    instance_double(Pnub::ClientWrapper, create_grants: true, grants_ttl: 1440)
  end

  let(:auth_cache) { instance_double(VhlChat::AuthCache, store_auth: true) }

  before do
    allow(Pnub::ClientWrapper).to receive(:new).and_return(pnub_client_wrapper)
    allow(pnub_client_wrapper).to receive(:chat_session_data).and_return([])
    allow(pnub_client_wrapper).to receive(:grants_successful?).and_return(true)
    allow(M3::Application.config).to receive(:chat_auth_cache)
                                       .and_return(instance_double(Redis))
    allow(VhlChat::AuthCache).to receive(:new).and_return(auth_cache)
  end

  def setup_svr()
    solo_video_recording.id = 1
    solo_video_recording.user = student_1
    solo_video_recording.activity = activity
    solo_video_recording.recording_path = "#{Rails.root}/spec/fixtures/media_items/svr.mp4"
  end

  def validate_grading_in_gradebook(student, points)
    score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
      student.id, section.id, activity.id
    ).first
    expect(score_action.points_earned.to_f).to eq(points.to_f)
    expect(score_action.pending).to be_falsey
  end


  xscenario 'As an instructor, I can grade solo video recording activities',
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
    create_gradebook_engine_submission(
      activity: activity,
      pending: true,
      section: section,
      student: student_1,
      submitted_at: Time.now.utc,
      time_spent: 123
    )

    create(:attempt_completed, activity: activity, section: section, user: student_2)
    create_gradebook_engine_submission(
      activity: activity,
      pending: true,
      section: section,
      student: student_2,
      submitted_at: Time.now.utc,
      time_spent: 245
    )
    setup_svr
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ApplicationController)
      .to receive(:chat_enabled?) { false }
    # rubocop:enable RSpec/AnyInstance

    #  # rubocop:disable RSpec/AnyInstance
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(VideoChatController)
      .to receive(:video_permission) { File.join('spec', 'fixtures', 'media_items', 'svr.mp4') }
    # rubocop:enable RSpec/AnyInstance
    #     # rubocop:enable RSpec/AnyInstance

    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Attempt).to receive(:results) { attempt_results }
    # rubocop:enable RSpec/AnyInstance
    #
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    # Go to the gradebook page showing activity-level scores.
    visit activities_for_lesson_url
    grade_cell = find(student_grade_selector(student_2.id))
    expect(grade_cell.text).to match(/Pending/)
    grade_cell = find(student_grade_selector(student_1.id))
    expect(grade_cell.text).to match(/Pending/)

    # Click the score to bring up the modal.
    grade_cell.click

    expect(find('.test-modal-content').text).to include('NOT YET GRADED')

    find('.test-modal-content a', text: 'Grade this Assignment').click

    for_grading_assignment do |pobject|
      # ensure that video file is on page
      expect(@page_object.find_by_id("recording_file").value).to include(solo_video_recording.recording_path)
      @page_object.student_answer('question_01', student_1).score = 8.0
      pobject.button(:done).click
    end
    validate_grading_in_gradebook(student_1,8.0)

    # review and regrade this student's work
    grade_cell = find(student_grade_selector(student_1.id))
    grade_cell.click
    find('.test-modal-content a', text: 'Review Student Work').click

    for_grading_assignment do |pobject|
      @page_object.student_answer('question_01', student_1).score = 9.0
      pobject.button(:done).click
    end
    validate_grading_in_gradebook(student_1, 9.0)

    visit instructor_grading_styles_path(
      program.id,
      activity.id,
      task_type: GradingTask::NEEDS_GRADING
    )
    choose('Student by student')
    click_on('start grading')

    for_grading_student_by_student do |pobject|
      purpose 'I see all the students that have submitted a question' do
        expect(pobject.selectable_students).to contain_exactly(
                                                    student_1.full_name + ' (graded)',
                                                    student_2.full_name
                                                  )
      end

      purpose 'I can grade the ungraded student' do
        initial_selected_student = pobject.selected_student
        # have find the ungraded student as the order in
        # the drop down appears to be random
        if (initial_selected_student.include?('graded'))
          pobject.button(:next).click
        end

        @page_object.student_answer('question_01', student_2).score = 7.5
        if (!initial_selected_student.include?('graded'))
          pobject.button(:next).click
        end
        pobject.button(:done).click
        validate_grading_in_gradebook(student_2, 7.5)
      end
    end
  end
end
