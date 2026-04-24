module ChatWidgetHelpers
  def expect_chat_widget_common_selectors
    step 'I can see the record button' do
      expect(page).to have_selector('.test-record-btn')
    end

    step 'I can see the pretest connection button' do
      expect(page).to have_selector('.test-pretest-connection-btn')
    end

    step 'I can see the file selector pseudo button' do
      expect(page).to have_selector('.test-file-selector-pseudo-btn')
    end

    step 'I can see the video player mic button' do
      expect(page).to have_selector('.test-video-player-mic-btn')
    end

    step 'I can see the mic on icon' do
      expect(page).to have_selector('.test-mic-on-icon')
    end

    step 'I cannot see the mic off icon' do
      expect(page).to have_no_selector('.test-mic-off-icon')
    end

    step 'I can see the video player camera button' do
      expect(page).to have_selector('.test-video-player-camera-btn')
    end

    step 'I can see the camera in on state' do
      expect(page).to have_selector('.test-camera-on-icon')
    end

    step 'I cannot see the camera in off' do
      expect(page).to have_no_selector('.test-camera-off-icon')
    end
  end

  def expect_mic_disable_flow
    step 'I can see a screen displaying message "No microphone detected or enabled."' do
      expect(page).to have_selector(
        '.test-no-video-stream',
        text: 'No microphone detected or enabled.'
      )
    end

    step 'I can see the mic in off state' do
      expect(page).to have_selector('.test-mic-off-icon')
    end

    step 'Reset the mic to the original state' do
      find('.test-video-player-mic-btn').click
    end
  end

  def expect_camera_disable_flow
    step 'I can see a screen displaying message "No camera detected or enabled."' do
      expect(page).to have_selector(
        '.test-no-video-stream',
        text: 'No camera detected or enabled.'
      )
    end

    step 'I can see the camera in off state' do
      expect(page).to have_selector('.test-camera-off-icon')
    end
  end

  def expect_mic_and_camera_disable_flow
    step 'I can see a screen displaying message "No camera and microphone detected or enabled."' do
      expect(page).to have_selector(
        '.test-no-video-stream',
        text: 'No camera and microphone detected or enabled.'
      )
    end

    step 'I can see the camera in off state' do
      expect(page).to have_selector('.test-camera-off-icon')
    end

    step 'I can see the mic in off state' do
      expect(page).to have_selector('.test-mic-off-icon')
    end
  end

  def expect_pretest_connection_flow
    step 'I can see the "Connectivity Test" dialog' do
      expect(page).to have_selector(
        '.test-dialog-box .test-dialog-heading',
        text: 'Connectivity Test'
      )
    end

    step 'I can see the "Test Connection" result message' do
      expect(page).to have_selector(
        '.test-result-message-text',
        text: 'Test failed due to technical reasons.'
      )
    end

    step 'I can see the audio quality as "Not Available"' do
      expect(page).to have_selector(
        '.test-result-stats-audio-body',
        text: 'Not Available'
      )
    end

    step 'I can see the video quality as "Not Available"' do
      expect(page).to have_selector(
        '.test-result-stats-video-body',
        text: 'Not Available'
      )
    end

    step 'I can see audio bar that changes level with audio' do
      expect(page).to have_selector('.test-audio-bar')
    end

    step 'I can see the "Re-test" button' do
      expect(page).to have_selector(
        '.test-pretest-again-btn',
        text: 'Re-test'
      )
    end

    step 'I can see the "Continue" button' do
      expect(page).to have_selector(
        '.test-continue-btn',
        text: 'Continue'
      )
    end

    step 'Click on "Re-test" button' do
      find('.test-pretest-again-btn').click
    end

    step 'I can see the "Connectivity Test" dialog' do
      expect(page).to have_selector(
        '.test-dialog-box .test-dialog-heading',
        text: 'Connectivity Test'
      )
    end

    step 'Click cross icon to close the PreTest modal' do
      within('.test-pretest-app') do
        find('.dialog-block__close-button').click
      end
    end

    step 'I cannot see the "Connectivity Test" dialog' do
      expect(page).to have_no_selector(
        '.test-dialog-box .test-dialog-heading',
        text: 'Connectivity Test'
      )
    end
  end

  def expect_video_upload_flow
    step 'I see submit button disabled initially' do
      expect(page).to have_button('Submit', disabled: true)
    end

    step 'Hover on the Upload Video button to see the upload related information' do
      find('.test-file-selector-pseudo-btn').hover
    end

    step 'I can see the tooltip with upload related information' do
      expect(page).to have_selector(
        '.test-tooltip-upload',
        visible: :visible
      )
    end

    step 'Select a file that needs to be upload' do
      attach_file(
        'video-upload',
        Rails.root.join('spec/fixtures/media_items/svr.mp4'),
        visible: false
      )
    end

    within('.test-attachment-info-container') do
      step 'I can see a video uploaded with the name svr.mp4' do
        expect(page).to have_selector(
          '.test-file-name',
          text: 'svr.mp4'
        )
      end

      step 'I can see a video uploaded of size 9.12 MB' do
        expect(page).to have_selector('.test-file-size', text: '(9.12 MB)')
      end
    end

    step 'I see submit button enabled' do
      expect(page).to have_button('Submit', disabled: false)
    end

    step 'I can see a cross icon near the uploaded file' do
      expect(page).to have_selector('.test-delete-btn')
    end

    step 'Click delete button to remove the uploaded video file' do
      find('.test-delete-btn').click
    end

    step 'I cannot see a video uploaded' do
      expect(page).to have_selector('.test-file-name', text: '')
    end
  end
end

