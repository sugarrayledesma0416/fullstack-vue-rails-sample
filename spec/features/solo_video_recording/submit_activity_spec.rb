feature 'Submit activity', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include ChatWidgetHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:school) { create(:school) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program:, chat_level: 'disabled') }
  let(:section) { create(:section, course:, instructor:) }
  let(:category) { create(:category, course:, penalty_percent: 0) }
  let(:activity) { create_solo_video_recording_activity(program) }
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

  def setup_solo_video_recording
    solo_video_recording.id = 1
    solo_video_recording.user = student
    solo_video_recording.activity = activity
    solo_video_recording.recording_path = Rails.root.join('spec/fixtures/media_items/svr.mp4')
  end

  before do
    allow(Maestro::CourseLicense).to receive(:all).and_return([])
    allow_any_instance_of(ActionController::Base).to receive(
      :protect_against_forgery?
    ).and_return(true)
    create(:school_user, user: student, school: school)
    create(:school_user, user: instructor, school: school)

    create(:enrollment, user: student, section:)
    create(
      :assignment,
      assignable: activity,
      category:,
      due_date: Date.tomorrow,
      section:
    )
    setup_solo_video_recording
  end

  scenario 'As an instructor, I see the solo video recording chat widget and submit button' \
           'disabled when the page loads' do
    allow_any_instance_of(
      SoloVideoRecordingUploader
    ).to receive(:upload).and_return({
      final_file_path: 'user-uploads/8472d4b9/archive.mp4',
      new_file_name: 'archive.mp4',
      original_filename: 'svr.mp4',
      s3_signed_url: 'https://partner-dummy-recordig.com/user-uploads/archive.mp4',
      success: true,
      uuid: 'db-bc1c-8472d4b9'
    })
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
    visit section_activity_path(section_id: section.id, id: activity.id)

    expect_chat_widget_common_selectors

    purpose 'When mic icon is clicked to disable the mic use' do
      find('.test-video-player-mic-btn').click

      expect_mic_disable_flow
    end

    purpose 'When camera icon is clicked to disable the camera use' do
      find('.test-video-player-camera-btn').click

      expect_camera_disable_flow
    end

    purpose 'When both camera and microphone icon is disabled' do
      find('.test-video-player-mic-btn').click

      expect_mic_and_camera_disable_flow
    end

    find('.test-pretest-connection-btn').click

    purpose 'When Pretest Connection is performed' do
      expect_pretest_connection_flow
    end

    step 'I see submit button as disabled' do
      expect(page).to have_button('Submit', disabled: true)
    end

    purpose 'When Video is uploaded' do
      expect_video_upload_flow
    end

    step 'I cannot see submit button as disabled' do
      expect(page).to have_no_button('Submit', disabled: true)
    end
  end

  scenario 'As a student, I see the solo video recording chat widget and submit disabled' \
           'when the page loads' do
    give_user_access_to_program(student, program)
    log_in_as(student)
    visit section_activity_path(section_id: section.id, id: activity.id)

    expect_chat_widget_common_selectors

    purpose 'When mic icon is clicked to disable the mic use' do
      find('.test-video-player-mic-btn').click

      expect_mic_disable_flow
    end
    
    purpose 'When camera icon is clicked to disable the camera use' do
      find('.test-video-player-camera-btn').click

      expect_camera_disable_flow
    end

    purpose 'When both camera and microphone icon is disabled' do
      find('.test-video-player-mic-btn').click

      expect_mic_and_camera_disable_flow
    end

    expect(page).to have_button('Submit', disabled: true)
  end

  scenario 'As a student, I see the solo video recording chat widget to upload video and submit' \
           'button enable' do
    allow_any_instance_of(
      SoloVideoRecordingUploader
    ).to receive(:upload).and_return({
      final_file_path: 'user-uploads/8472d4b9/archive.mp4',
      new_file_name: 'archive.mp4',
      original_filename: 'svr.mp4',
      s3_signed_url: 'https://partner-dummy-recordig.com/user-uploads/archive.mp4',
      success: true,
      uuid: 'db-bc1c-8472d4b9'
    })
    give_user_access_to_program(student, program)
    log_in_as(student)
    visit section_activity_path(section_id: section.id, id: activity.id)

    purpose 'When Video is uploaded' do
      expect_video_upload_flow
    end

    step 'I cannot see submit button as disabled' do
      expect(page).to have_no_button('Submit', disabled: true)
    end
  end

  scenario 'As a student, I see the solo video recording chat widget and click test connection' do
    give_user_access_to_program(student, program)
    log_in_as(student)
    visit section_activity_path(section_id: section.id, id: activity.id)

    find('.test-pretest-connection-btn').click
    purpose 'When Pretest Connection is performed' do
      expect_pretest_connection_flow
    end
  end

  # This scenario is temporaly unavailable because there are some TokBox requests that I
  # can't mock from Ruby side
  xscenario 'As a student, I see the submit button disabled after the activity is submitted',
            skip: 'there are some TokBox requests that can not be mock from Ruby side' do
    give_user_access_to_program(student, program)
    log_in_as(student)
    visit section_activity_path(section_id: section.id, id: activity.id)

    purpose 'create a record' do
      find('.js-rec-btn > button').click(wait: 5) # start recording
      find('.js-rec-btn > button').click # stop recording
      wait_for_ajax
    end

    click_button 'Submit'
    wait_for_ajax

    expect(page).to have_button('Submit', disabled: true)
  end

  scenario 'As a student, I do not see the submit button if I open the activity in practice mode' do
    attempt = create(:attempt_completed, activity:, section:, user: student)

    allow(attempt).to receive(:results) { attempt_results }
    give_user_access_to_program(student, program)
    log_in_as(student)
    visit practice_section_activity_path(section_id: section.id, id: activity.id)

    expect_chat_widget_common_selectors

    purpose 'When mic icon is clicked to disable the mic use' do
      find('.test-video-player-mic-btn').click

      expect_mic_disable_flow
    end

    purpose 'When camera icon is clicked to disable the camera use' do
      find('.test-video-player-camera-btn').click

      expect_camera_disable_flow
    end

    purpose 'When both camera and microphone icon is disabled' do
      find('.test-video-player-mic-btn').click

      expect_mic_and_camera_disable_flow
    end

    expect(page).to have_no_button('Submit', disabled: true)
  end
end
