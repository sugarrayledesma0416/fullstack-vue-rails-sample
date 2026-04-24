feature 'Table Inline Open-Ended activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include CapybaraViewHelpers
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
      allows_review_requests: true
    )
  end

  let(:section) { create(:section, course: course, instructor: instructor) }

  let!(:media_items) do
    Array.new(4) do |i|
      id = i + 1
      create(:media_item_image, filename: "multiple_choice_prompt_#{id}.gif")
    end
  end

  let(:activity) { create_table_inline_open_ended_activity(program) }

  let(:activity_data) do
    ActivityTest::ActivityData::TableInlineOpenEnded.new(activity, media_items).tap do |act|
      act.input_type = 'input'
    end
  end

  # new activity, start with no submission
  let(:fake_submissions) { {} }
  let(:answers_saved_no_submitted_msg) do
    'Your answers will be SAVED. They will NOT be submitted for a grade.'
  end
  let(:one_question_not_answered_msg) { '1 question is unanswered.' }
  let(:two_questions_not_answered_msg) { '2 questions are unanswered.' }
  let(:no_changes_to_save_msg) { 'No changes to save!' }
  let(:blank_response) { '(No student response)' }

  context 'as a student' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    def expect_question_contents_to_be_displayed
      activity_data.questions.each do |question_data|
        question = from_table_inline_open_ended_question(question_data.rank, 1)
        question = from_table_inline_open_ended_question(question_data.rank, 2)
        expect_element_table_to_be_displayed(question)
      end
    end

    scenario 'I can request help and reviews', nondeterministic: true do
      ignoring_angular do
        direction_line_help_request_comment = 'request help on the direction line'
        question_help_request_comment = 'some request help comment'

        visit section_activity_path(section.id, activity)
        for_preview_page(activity_data) do
          # Add an help request on the direction line and on a question
          {
            from_direction_line => direction_line_help_request_comment,
            from_table_inline_open_ended_question(1, 1) => question_help_request_comment
          }.each do |item, item_comment|
            # insert 2 comments. The first one is a temporary one, it will be deleted
            comments = ['some temporary comment', item_comment]
            comments.each do |comment|
              validate_adding_instructor_help_request(
                item: item,
                comment: comment,
                helpable: [
                  from_direction_line,
                  # non empty question prompts are helpable
                  from_table_inline_open_ended_question(1, 1)
                ],
                non_helpable: []
              )
            end
            expect_help_request_to_be_displayed(
              item: item, request_number: 1, comment: comments[0]
            )
            expect_help_request_to_be_displayed(
              item: item, request_number: 2, comment: comments[1]
            )
            remove_help_request(item: item, request_number: 1)
            expect_help_request_to_be_displayed(
              item: item, request_number: 1, comment: comments[1]
            )
          end

          # Fill in answers for wols 1 and 2 for question 1
          from_table_inline_open_ended_question(1, 1).choose_answer('some answer for question 1-1')
          from_table_inline_open_ended_question(1, 2).choose_answer('some answer for question 1-2')
          # Fill in answers for wol 1 for question 2
          from_table_inline_open_ended_question(2, 1).choose_answer('some answer for question 2-1')
          # leave wol 2 blank for question 2

          accept_alert do
            @page_object.button(:submit).click
          end
        end

        for_submit_page(activity_data) do
          # help requests are displayed
          {
            from_direction_line => direction_line_help_request_comment,
            from_table_inline_open_ended_question(1, 1) => question_help_request_comment
          }.each do |item, comment|
            # expect_help_request_to_be_displayed(
              # item: item, request_number: 1, comment: comment
            # )
          end

          accept_alert do
            @page_object.button(:accept).click
          end
        end

        for_accept_page(activity_data) do
          # help requests are displayed
          {
            from_direction_line => direction_line_help_request_comment,
            from_table_inline_open_ended_question(1, 1) => question_help_request_comment
          }.each do |item, comment|
            expect_help_request_to_be_displayed(
              item: item, request_number: 1, comment: comment
            )
          end

          # Request review
          expect(from_direction_line).not_to be_helpable
          # Since a review can only be requested for incorrect answers and all the
          # answers are pending, we just check that they are not helpable
          expect(from_table_inline_open_ended_question(1, 1)).not_to be_helpable
          expect(from_table_inline_open_ended_question(1, 1).answer).not_to be_helpable
        end

        attempt = Attempt.active_attempt(student, section, activity)
        # Grade question_01_wol_1 as correct
        question_data = activity_data.question(1)
        FeedbackItem.create!(
          attempt: attempt,
          points_earned: 2.0,
          question_label: format('question_%02d_wol_1', question_data.rank),
          section: section,
          user: student
        )
        # Grade question_01_wol_2 as partially correct
        question_data = activity_data.question(1)
        FeedbackItem.create!(
          attempt: attempt,
          points_earned: 1.8,
          question_label: format('question_%02d_wol_2', question_data.rank),
          section: section,
          user: student
        )
        # Keep question_02 wol_1 and wol_2 as pending

        visit section_activity_path(section.id, activity)
        for_complete_page(activity_data) do
          # help requests are displayed
          {
            from_direction_line => direction_line_help_request_comment,
            from_table_inline_open_ended_question(1, 1) => question_help_request_comment
          }.each do |item, comment|
            expect_help_request_to_be_displayed(
              item: item, request_number: 1, comment: comment
            )
          end

          # Review request
# =begin This section is failing because the browser is not allowing help anywhere
          with_element(from_table_inline_open_ended_question(2, 1).answer) do |item|
            comments = [
              'some request review comment',
              'another request review comment'
            ]
            comments.each do |comment|
              validate_adding_instructor_review_request(
                item: item,
                comment: comment,
                helpable: [
                  # Partially correct answer is helpable
                  from_table_inline_open_ended_question(1, 2).answer,
                  # Pending answer is helpable
                  from_table_inline_open_ended_question(2, 1).answer,
                ],
                non_helpable: [
                  from_direction_line,
                  # correct answer is not helpable
                  from_table_inline_open_ended_question(1, 1).answer,
                  # empty answer is not helpable
                  from_table_inline_open_ended_question(2, 2).answer
                ]
              )
            end
            expect_review_request_to_be_displayed(
              item: item, request_number: 1, comment: comments[0]
            )
            expect_review_request_to_be_displayed(
              item: item, request_number: 2, comment: comments[1]
            )
            remove_review_request(item: item, request_number: 1)
            expect_review_request_to_be_displayed(
              item: item, request_number: 1, comment: comments[1]
            )
          end
# =end
        end

        # Because the last request in this test is asynchronous, the test can
        # start tearing down the data (truncating activities table) before
        # the request completes, causing a validation error:
        # Validation failed: Activity must exist
        # Adding this bogus "visit" call prevents the teardown from starting
        # until after the help request is saved.
        visit section_activity_path(section.id, activity)
      end
    end

    scenario 'I can use the accent bar to insert special characters' do
      visit section_activity_path(section.id, activity)
      for_preview_page(activity_data) do
        str = 'blah'
        # set initial answer (it's used to focus the input field)
        from_table_inline_open_ended_question(1, 1).choose_answer(str)

        # Open Accent bar modal for the current input.
        page.find('#question_01').click
        page.find('.test-accent-bar-launcher').click
        accent_bar = page.find('.test-accent-bar-modal')

        # click all buttons in lower case(default)
        lower_case_buttons = accent_bar.find_all('test-accent-bar-char')
        lower_case_buttons.each do |button|
          button.click
          str += button.text
        end

        # Switch to upper case & click on upper case button.
        accent_bar.find('.test-accent-bar-case-option-upper').click
        upper_case_buttons = accent_bar.find_all('test-accent-bar-char')
        upper_case_buttons.each do |button|
          button.click
          str += button.text
        end
        expect(from_table_inline_open_ended_question(1, 1).answer.text).to eq(str)
      end
    end

    scenario 'my answers are sanitized' do
      harmful_answer = '<script type="text/javascript">window.close();</script>blah'
      sanitized_answer = 'window.close();blah'

      visit section_activity_path(section.id, activity)
      for_preview_page(activity_data) do
        # Try harmful answer
        from_table_inline_open_ended_question(1, 1).choose_answer(harmful_answer)
        # And save
        click_save_button_expect_message(answers_saved_no_submitted_msg)
      end
      # and reload the page
      visit section_activity_path(section.id, activity)
      for_decide_page(activity_data) do
        # Response should have been sanitized
        expect(from_table_inline_open_ended_question(1, 1).answer.text).to eq(sanitized_answer)
        # Try harmfull answer
        from_table_inline_open_ended_question(1, 1).choose_answer(harmful_answer)
        # And submit
        accept_alert do
          @page_object.button(:submit).click
        end
      end

      for_submit_page(activity_data) do
        # Response should have been sanitized
        expect(from_table_inline_open_ended_question(1, 1).answer.text).to eq(sanitized_answer)
      end
    end

    scenario 'I can do a table inline open ended activity' do
      question_1_wol_1_answer = ''
      question_1_wol_2_answer = ''
      question_2_wol_1_answer = ''
      question_2_wol_2_answer = ''

      visit section_activity_path(section.id, activity)
      for_preview_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(3)

        (1..2).each do |q_num|
          (1..2).each do |w_num|
            from_table_inline_open_ended_question(q_num, w_num) do |wol|
              expect(wol).to be_marked(:blank)
              expect(wol.answer.text).to eq('')
            end
          end
        end

        question_1_wol_1_answer = 'some random answer for wol 1'
        question_1_wol_2_answer = 'some random answer for wol 2'

        from_table_inline_open_ended_question(1, 1).choose_answer(question_1_wol_1_answer)
        from_table_inline_open_ended_question(1, 2).choose_answer(question_1_wol_2_answer)

        click_save_button_expect_message(answers_saved_no_submitted_msg)
        expect_flash_message(:notice, 'Your changes have been saved.')
      end

      # Reload the page
      visit section_activity_path(section.id, activity)
      for_decide_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(3)

        # Every question should be marked as changed
        # and choices that were previously chosen and saved are already selected
        [
          [question_1_wol_1_answer, question_1_wol_2_answer],
          ['', '']
        ].each.with_index(1) do |answers, q_num|
          answers.each.with_index(1) do |answer, w_num|
            from_table_inline_open_ended_question(q_num, w_num) do |wol|
              #expect(wol).to be_marked(:changed)
              expect(wol.answer.text).to eq(answer)
            end
          end
        end

        click_button_expect_alert(:submit, two_questions_not_answered_msg)
      end

      for_submit_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        # Every question should be marked as pending
        [
          [question_1_wol_1_answer, question_1_wol_2_answer],
          ['', '']
        ].each.with_index(1) do |answers, q_num|
          answers.each.with_index(1) do |answer, w_num|
            from_table_inline_open_ended_question(q_num, w_num) do |wol|
              #expect(wol).to be_marked(:pending)
              expect(wol.answer.text).to eq(answer)
            end
          end
        end

        @page_object.button(:retry).click
      end

      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        # Every question should be marked as pending
        [
          [question_1_wol_1_answer, question_1_wol_2_answer],
          ['', '']
        ].each.with_index(1) do |answers, q_num|
          answers.each.with_index(1) do |answer, w_num|
            from_table_inline_open_ended_question(q_num, w_num) do |wol|
              #expect(wol).to be_marked(:pending)
              expect(wol.answer.text).to eq(answer)
            end
          end
        end

        # Change question 1-2 answer
        question_1_wol_2_answer = 'A different answer for question 2'
        from_table_inline_open_ended_question(1, 2).choose_answer(question_1_wol_2_answer)

        # and save without submitting
        click_save_button_expect_message(answers_saved_no_submitted_msg)
        expect_flash_message(:notice, 'Your changes have been saved.')
      end

      # Reload the page
      visit section_activity_path(section.id, activity)
      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        # Every question should be marked as pending or changed
        from_table_inline_open_ended_question(1, 1) do |question|
          #expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_1_wol_1_answer)
        end

        from_table_inline_open_ended_question(1, 2) do |question|
          #expect(question).to be_marked(:changed)
          expect(question.answer.text).to eq(question_1_wol_2_answer)
        end

        (1..2).each do |number|
          from_table_inline_open_ended_question(2, number) do |question|
            #expect(question).to be_marked(:pending)
            expect(question.answer.text).to eq('')
          end
        end

        # Save without making any changes should trigger a popup
        click_save_button_expect_message(no_changes_to_save_msg)

        # Submit the activity
        click_button_expect_alert(:submit, two_questions_not_answered_msg)
      end

      for_submit_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(1)

        # Every question should be marked as pending
        [
          [question_1_wol_1_answer, question_1_wol_2_answer],
          ['', '']
        ].each.with_index(1) do |answers, q_num|
          answers.each.with_index(1) do |answer, w_num|
            from_table_inline_open_ended_question(q_num, w_num) do |wol|
              #expect(wol).to be_marked(:pending)
              expect(wol.answer.text).to eq(answer)
            end
          end
        end

        click_button_expect_alert(:accept, 'You have chosen to accept your grade of 0.0%.')
      end

      for_accept_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(nil)

        # Every question should be marked as pending
        [
          [question_1_wol_1_answer, question_1_wol_2_answer],
          [blank_response, blank_response]
        ].each.with_index(1) do |answers, q_num|
          answers.each.with_index(1) do |answer, w_num|
            from_table_inline_open_ended_question(q_num, w_num) do |wol|
              expect(wol).to be_marked(:pending)
              expect(wol.answer.text).to eq(answer)
            end
          end
        end

        from_table_inline_open_ended_question(1, 2) do |wol|
          expect(wol).to be_marked(:pending)
          expect(wol.answer.text).to eq(question_1_wol_2_answer)
          # Click the sample answer link to show the sample answer
          wol.sample_answers.show
          # And check all sample answers
          1.upto(activity_data.question(1).wols.last.sample_answers.size) do |i|
            expect(
              wol.sample_answers.answer(i).text
            ).to eq(activity_data.question(1).wols.last.sample_answers[i - 1])
          end
        end

        from_table_inline_open_ended_question(2, 1) do |wol|
          expect(wol).to be_marked(:pending)
          expect(wol.answer.text).to eq(blank_response)
          # Click the sample answer link to show the sample answer
          wol.sample_answers.show
          # And check all sample answers
          1.upto(activity_data.question(2).wols.last.sample_answers.size) do |i|
            expect(
              wol.sample_answers.answer(i).text
            ).to eq(activity_data.question(2).wols.last.sample_answers[i - 1])
          end
        end
      end
    end
  end

  scenario 'As an instructor, answer key view exists' do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    msg = 'Answer key mode. All correct answers will be displayed'
    visit section_activity_path(0, activity)
    for_preview_page(activity_data) do
      click_link('Answer key')
      expect(page).to have_selector('.test-flash-notice', text: msg)
    end
  end
end
