def create_drop_down_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'dropdown.xml'),
    program,
    grading_method: 'auto'
  )
end

def create_audio_reference_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'audio_reference_activity.xml'),
    program,
    grading_method: 'auto'
  )
end

def create_html_reading_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'html_reading.xml'),
    program
  )
end

feature 'Audio reference activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) do
    create(
      :course,
      owner: instructor,
      program: program,
      allows_help_requests: true,
      allow_audio_transcripts: false,
      allows_review_requests: true
    )
  end

  let(:course_with_audio_transcripts) do
    create(
      :course,
      owner: instructor,
      program: program,
      allows_help_requests: true,
      allow_audio_transcripts: true,
      allows_review_requests: true
    )
  end

  let(:sample_transcript) { 'Sample transcript text' }

  let(:section) do
    create(:section, course: course, instructor: instructor)
  end

  let(:section_with_audio_transcripts) do
    create(:section, course: course_with_audio_transcripts, instructor: instructor)
  end

  # ID is needed because is specified in audio_reference_activity.xml
  let!(:media_item_without_transcript) do
    create(:media_item_audio, id: 1, filename: 'vocab_list_audio_1.mp3')
  end

  # ID is needed because is specified in audio_reference_activity.xml
  let!(:media_item_with_transcript) do
    create(
      :media_item_audio,
      id: 2,
      filename: 'vocab_list_audio_2.mp3',
      transcript: sample_transcript
    )
  end

  # a dropdown activity that contains audio reference media item with transcripts
  let(:activity_with_transcripts) { create_audio_reference_activity(program) }
  let(:activity_data_with_transcripts) do
    ActivityTest::ActivityData::DropDown.new(
      activity_with_transcripts,
      [media_item_without_transcript, media_item_with_transcript]
    )
  end

  # a dropdown activity without audio reference media item and transcripts
  let(:activity_without_transcripts) { create_drop_down_activity(program) }
  let(:activity_data_without_transcripts) do
    ActivityTest::ActivityData::DropDown.new(activity_without_transcripts, [])
  end

  # an html_reading activity with a transcript
  let(:html_reading_activity_with_transcripts) { create_html_reading_activity(program) }
  let(:activity_data_with_transcripts) do
    ActivityTest::ActivityData::HtmlReading.new(
      activity_with_transcripts
    )
  end

  def expect_no_media_player
    expect(page).to have_no_selector('.player')
  end

  def expect_media_player
    expect(page).to have_selector('.player')
  end

  def expect_no_audio_transcript_control
    expect(page).to have_no_selector('.test-transcript-disclosure')
  end

  def expect_audio_transcript_control
    expect(page).to have_selector('.test-transcript-disclosure')
    expect(
      page.find('.test-transcript-disclosure__header').text
    ).to eq('SHOW AUDIO TRANSCRIPT')
  end

  scenario 'As a student, I see transcripts when enabled in my course' do
    give_user_access_to_program(student, program)
    log_in_as(student)

    purpose 'Visit activities without being enrolled in any course' do
      purpose 'Visit an activity with an audio media item and transcripts' do
        # Students without enrollment always open activities in section zero.
        visit section_activity_path(0, activity_with_transcripts)
        for_preview_page(activity_data_with_transcripts) do
          expect_activity_shell_structure_to_be_complete
        end

        expect_media_player
        expect_no_audio_transcript_control
      end

      purpose 'Visit an activity with no audio media item or transcripts' do
        # Students without enrollment always open activities in section zero.
        visit section_activity_path(0, activity_without_transcripts)
        for_preview_page(activity_data_without_transcripts) do
          expect_activity_shell_structure_to_be_complete
        end

        expect_no_media_player
        expect_no_audio_transcript_control
      end
    end

    purpose 'Visit activities in a course with transcripts enabled' do
      step 'Enroll in course with audio transcripts enabled' do
        create(
          :active_enrollment,
          section: section_with_audio_transcripts,
          user: student
        )
      end

      purpose 'Visit an activity with an audio media item and transcripts' do
        allow_any_instance_of(ProgramSettings).to receive(:has_audio_transcripts?).and_return(true)
        visit section_activity_path(
          section_with_audio_transcripts.id,
          activity_with_transcripts
        )
        for_preview_page(activity_data_with_transcripts) do
          expect_activity_shell_structure_to_be_complete
        end

        expect_media_player
        expect_audio_transcript_control

        purpose 'Opening the audio transcript' do
          step 'Click the audio transcript control to open it' do
            page.find('.test-transcript-disclosure__header').click
          end
          purpose 'I see the label for the control change to "HIDE AUDIO TRANSCRIPT"' do
            expect(
              page.find('.test-transcript-disclosure__header').text
            ).to eq('HIDE AUDIO TRANSCRIPT')
          end
          purpose 'I see the content of the transcript' do
            expect(
              page.find('.test-transcript-disclosure')
            ).to have_content(sample_transcript)
          end
        end
      end
    end

    purpose 'Show transcript for html_reading activity' do
    # if transcripts are enabled, always show for an html_reading activity
      visit section_activity_path(
        section_with_audio_transcripts.id,
        html_reading_activity_with_transcripts)
      expect_media_player
      expect_audio_transcript_control
    end

    purpose 'Visit an activity with no audio media item or transcripts' do
      visit section_activity_path(
        section_with_audio_transcripts.id,
        activity_without_transcripts
      )
      for_preview_page(activity_data_without_transcripts) do
        expect_activity_shell_structure_to_be_complete
      end

      expect_no_media_player
      expect_no_audio_transcript_control
    end

    purpose 'Visit activities in a course with transcripts disabled' do
      step 'Change student enrollment' do
        Enrollment.where(user_id: student.id).delete_all
        create(:active_enrollment, section: section, user: student)
      end

      purpose 'Visit an activity with an audio media item and transcripts' do
        visit section_activity_path(section.id, activity_with_transcripts)

        expect_media_player
        expect_no_audio_transcript_control
      end

      purpose 'Visit an activity with no audio media item or transcripts' do
        visit section_activity_path(section.id, activity_without_transcripts)

        expect_no_media_player
        expect_no_audio_transcript_control
      end

      purpose 'Show transcript for html_reading activity' do
      # if transcripts are disabled, do not show for html_reading activities
        visit section_activity_path(
          section_with_audio_transcripts.id,
          html_reading_activity_with_transcripts)
        expect_media_player
        expect_no_audio_transcript_control
      end
    end
  end
  # end scenario

  scenario 'As a student, I do not see audio transcripts if they are disabled via student configs' do
    give_user_access_to_program(student, program)
    log_in_as(student)

    purpose 'Visit activities in a course with transcripts enabled' do
      step 'Change student enrollment' do
        Enrollment.where(user_id: student.id).delete_all
        create(:active_enrollment, section: section_with_audio_transcripts, user: student)
      end

      step 'Disable transcripts via student section config' do
        allow_any_instance_of(ProgramSettings).to receive(:has_audio_transcripts?).and_return(true)
        create(
          :student_section_config,
          section_id: section_with_audio_transcripts.id,
          user_id: student.id,
          audio_transcript: false
        )
      end

      purpose 'Visit an activity with an audio media item and transcripts' do
        visit section_activity_path(section_with_audio_transcripts.id, activity_with_transcripts)

        expect_media_player
        expect_no_audio_transcript_control
      end
    end
  end
  # end scenario

  scenario 'As a student, I see audio transcripts if they are enabled via student configs' do
    give_user_access_to_program(student, program)
    log_in_as(student)

    purpose 'Visit activities in a course with transcripts disabled' do
      step 'Change student enrollment' do
        Enrollment.where(user_id: student.id).delete_all
        create(:active_enrollment, section: section, user: student)
      end

      step 'Enable transcripts via student section config' do
        allow_any_instance_of(ProgramSettings).to receive(:has_audio_transcripts?).and_return(true)
        create(
          :student_section_config,
          section_id: section.id,
          user_id: student.id,
          audio_transcript: true
        )
      end

      purpose 'Visit an activity with an audio media item and transcripts' do
        visit section_activity_path(section.id, activity_with_transcripts)
        expect_media_player
        expect_audio_transcript_control
      end

      purpose 'Opening the audio transcript' do
        step 'Click the audio transcript control to open it' do
          page.find('.test-transcript-disclosure__header').click
        end

        purpose 'I see the label for the control change to "HIDE AUDIO TRANSCRIPT"' do
          expect(
            page.find('.test-transcript-disclosure__header').text
          ).to eq('HIDE AUDIO TRANSCRIPT')
        end

        purpose 'I see the content of the transcript' do
          expect(
            page.find('.test-transcript-disclosure')
          ).to have_content(sample_transcript)
        end
      end
    end
  end
  # end scenario

  scenario 'As an instructor, I see transcripts only when enabled for a program' do
    give_user_access_to_program(instructor, program)
    log_in_as(instructor)

    purpose 'Visit activities in a program with audio transcripts enabled' do
      allow_any_instance_of(ProgramSettings).to receive(:has_audio_transcripts?)
        .and_return(true)

      purpose 'Visit an activity with an audio media item and transcripts' do
        # Instructor always open activities in section zero.
        visit section_activity_path(0, activity_with_transcripts)
        for_preview_page(activity_data_with_transcripts) do
          expect_activity_shell_structure_to_be_complete
        end

        expect_media_player
        expect_audio_transcript_control

        purpose 'Opening the audio transcript' do
          step 'Click the audio transcript control to open it' do
            page.find('.test-transcript-disclosure__header').click
          end
          purpose 'I see the label for the control change to "HIDE AUDIO TRANSCRIPT"' do
            expect(
              page.find('.test-transcript-disclosure__header').text
            ).to eq('HIDE AUDIO TRANSCRIPT')
          end
          purpose 'I see the content of the transcript' do
            expect(
              page.find('.test-transcript-disclosure')
            ).to have_content(sample_transcript)
          end
        end
      end

      purpose 'Visit an activity with no audio media item or transcripts' do
        visit section_activity_path(0, activity_without_transcripts)
        for_preview_page(activity_data_without_transcripts) do
          expect_activity_shell_structure_to_be_complete
        end

        expect_no_media_player
        expect_no_audio_transcript_control
      end
    end

    purpose 'Visit activities in a program with audio transcripts enabled' do
      allow_any_instance_of(ProgramSettings).to receive(:has_audio_transcripts?)
        .and_return(false)

      purpose 'Visit an activity with an audio media item and transcripts' do
        # Instructor always open activities in section zero.
        visit section_activity_path(0, activity_with_transcripts)
        for_preview_page(activity_data_with_transcripts) do
          expect_activity_shell_structure_to_be_complete
        end

        expect_media_player
        expect_no_audio_transcript_control
      end

      purpose 'Visit an activity with no audio media item or transcripts' do
        visit section_activity_path(0, activity_without_transcripts)
        for_preview_page(activity_data_without_transcripts) do
          expect_activity_shell_structure_to_be_complete
        end

        expect_no_media_player
        expect_no_audio_transcript_control
      end
    end
  end
  # end scenario
end
