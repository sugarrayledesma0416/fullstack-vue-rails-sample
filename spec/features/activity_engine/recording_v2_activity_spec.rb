def create_recording_v2_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'recording_v2.xml'),
    program,
    grading_method: 'instructor',
    # All recording v2 activities have only one attempt
    max_attempts: 1
  )
end

feature 'Open ended activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include CapybaraViewHelpers
  include ActivityTest::Helpers
  include ActivityTest::RecordingV2Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) do
    create(:course,
           owner: instructor,
           program: program,
           allow_audio_transcripts: true,
           allows_help_requests: true,
           allows_review_requests: true)
  end
  let(:section) { create(:section, course: course, instructor: instructor) }

  # Both ids are needed because those are specified in the recording_v2 fixture.
  let!(:media_items) do
    [
      create(
        :media_item_audio,
        filename: 'vocab_list_audio_1.mp3',
        id: 1,
        transcript: 'Audio file 1 transcription'
      ),
      create(:media_item_audio, id: 2, filename: 'vocab_list_audio_2.mp3')
    ]
  end
  let(:activity) { create_recording_v2_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::RecordingV2.new(activity, media_items) }
  # new activity, start with no submission
  let(:fake_submissions) { {} }

  before do
    stub_const(
      'MediaItem::CDN_URL_PREFIX',
      "#{Capybara.app_host}:#{Capybara.current_session.server.port}"
    )
  end

  context 'as a student' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    def expect_question_contents_to_be_displayed
      activity_data.questions.each do |question_data|
        question = from_recording_v2_question(question_data.rank)
        expect_element_prompt_to_be_displayed(question, question_data.prompt)
      end
    end

    scenario 'I can request help and reviews', nondeterministic: true do
        direction_line_help_request_comment = 'request help on the direction line'
        question_help_request_comment = 'some request help comment'

        visit section_activity_path(section.id, activity)
        for_preview_page(activity_data) do
          # Add an help request on the direction line and on a question
          { from_direction_line => direction_line_help_request_comment,
            from_recording_v2_question(1) => question_help_request_comment }.each do |item, item_comment|
            # insert 2 comments. The first one is a temporary one, it will be deleted
            comments = ['some temporary comment', item_comment]
            comments.each do |comment|
              validate_adding_instructor_help_request(
                item: item,
                comment: comment,
                helpable: [
                  from_direction_line,
                  # non empty question prompts are helpable
                  from_recording_v2_question(1),
                  from_recording_v2_question(2),
                  from_recording_v2_question(3)
                ],
                non_helpable: [ ]
              )
            end
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[0])
            expect_help_request_to_be_displayed(item: item, request_number: 2, comment: comments[1])
            remove_help_request(item: item, request_number: 1)
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[1])
          end

          accept_alert do
            @page_object.button(:submit).click
          end
        end

        for_accept_page(activity_data) do
          # help requests are displayed
          { from_direction_line => direction_line_help_request_comment,
            from_recording_v2_question(1) => question_help_request_comment }.each do |item, comment|
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comment)
          end

          # Request review
          expect(from_direction_line).not_to be_helpable
          # Since a review can only be requested for incorrect answers and all the
          # answers are pending, we just check that they are not helpable
          (1..3).each do |qnum|
            expect(from_recording_v2_question(qnum)).not_to be_helpable
          end
        end

        # Because the last request in this test is asynchronous, the test can
        # start tearing down the data (truncating activities table) before
        # the request completes, causing a validation error:
        # Validation failed: Activity must exist
        # Adding this bogus "visit" call prevents the teardown from starting
        # until after the help request is saved.
        visit section_activity_path(section.id, activity)
    end

    xscenario 'I complete a recording v2 activity' do
      pending 'This scenario is failing because of MAE-52674'
      visit section_activity_path(section, activity)
      for_preview_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(1)

        (1..3).each do |number|
          from_recording_v2_question(number) do |question|
            expect(question).to be_marked(:blank)
          end
        end

        purpose 'Listen buttons are enabled, others are disabled' do
          from_recording_v2_question(1) do |question|
            expect(question.button(:listen)).to be_enabled
            expect(question.button(:record)).to be_disabled
            expect(question.button(:review)).to not_exist
          end

          from_recording_v2_question(2) do |question|
            # There is no prompt, the record button is already enabled
            expect(question.button(:listen)).to not_exist
            expect(question.button(:record)).to be_enabled
            expect(question.button(:review)).to not_exist
          end

          from_recording_v2_question(3) do |question|
            expect(question.button(:listen)).to be_enabled
            expect(question.button(:record)).to be_disabled
            expect(question.button(:review)).to not_exist
          end
        end

        from_recording_v2_question(1) do |question|
          listen_to_question(question)

          purpose 'Now the record button is enabled and the review button is still not visible' do
            expect(question.button(:record)).to be_enabled
            expect(question.button(:review)).to not_exist
          end

          record_audio_file(question)

          expect { listen_to_review(question) }.not_to raise_error
        end

        purpose 'I can show/hide the audio transcriptions' do
          from_recording_v2_question(1) do |question|
            expect(question).to have_no_prompt_transcription
          end

          @page_object.show_transcriptions

          from_recording_v2_question(1) do |question|
            expect(question.prompt_transcription).to eq(media_items[0].transcript)
          end

          @page_object.hide_transcriptions

          from_recording_v2_question(1) do |question|
            expect(question).to have_no_prompt_transcription
          end
        end

        purpose 'Showing the audio transcriptions enables all the record buttons' do
          [1, 2, 3].each do |question_rank|
            from_recording_v2_question(question_rank) do |question|
              expect(question.button(:record)).to be_enabled
            end
          end
        end

        from_recording_v2_question(2) do |question|
          record_audio_file(question)
        end

        from_recording_v2_question(3) do |question|
          # Do not record anything
        end

        purpose 'I see an alert about an unanswered question when I submit the activity' do
          click_button_expect_alert(:submit, '1 question is unanswered.')
        end
      end

      purpose 'I see a success message' do
        expect_flash_message(:notice, 'Activity complete.')
      end

      for_accept_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed

        # Every question should be marked as pending
        from_recording_v2_question(1) do |question|
          expect(question).to be_marked(:pending)
          expect(question.button(:listen)).to be_enabled
          expect(question.button(:review)).to be_enabled
          expect(question.button(:answer)).to be_enabled
        end

        from_recording_v2_question(2) do |question|
          expect(question).to be_marked(:pending)
          expect(question.button(:listen)).to not_exist
          expect(question.button(:review)).to be_enabled
          expect(question.button(:answer)).to be_enabled
        end

        from_recording_v2_question(3) do |question|
          expect(question).to be_marked(:pending)
          expect(question.button(:listen)).to be_enabled
          step 'The review button is disabled because we did not record anything' do
            expect(question.button(:review)).to be_disabled
          end
          expect(question.button(:answer)).to be_enabled
        end

        purpose 'I can show/hide the audio transcriptions' do
          from_recording_v2_question(1) do |question|
            expect(question).to have_no_prompt_transcription
          end

          @page_object.show_transcriptions

          from_recording_v2_question(1) do |question|
            expect(question.prompt_transcription).to eq(media_items[0].transcript)
          end

          @page_object.hide_transcriptions

          from_recording_v2_question(1) do |question|
            expect(question).to have_no_prompt_transcription
          end
        end
      end
    end
  end

  scenario 'As an instructor, answer key view exists' do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    visit section_activity_path(0, activity)
    for_preview_page(activity_data) do
      click_link('Answer key')
      expect_flash_message(:notice, 'Answer key mode. All correct answers will be displayed')
    end
  end
end
