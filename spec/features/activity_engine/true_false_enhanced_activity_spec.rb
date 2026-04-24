feature 'True false enhanced activity', js: true, chrome: true, new_gb_sync: true, retry: 2 do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) do
    create(:course,
           owner: instructor,
           program: program,
           allows_help_requests: true,
           allows_review_requests: true)
  end
  let(:section) { create(:section, course: course, instructor: instructor) }

  # ID is needed here because is specified in fixture file.
  let!(:media_items) do
    Array.new(4) do |i|
      id = i + 1
      create(:media_item_image, id: id, filename: "multiple_choice_prompt_#{id}.gif")
    end
  end

  let(:activity) { create_true_false_enhanced_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::TrueFalseEnhanced.new(activity, media_items) }
  let(:fake_submissions) { {} }
  let(:answers_saved_no_submitted_msg) do
    'Your answers will be SAVED. They will NOT be submitted for a grade.'
  end
  let(:one_question_not_answered_msg) { '1 question is unanswered.' }
  let(:no_changes_to_save_msg) { 'No changes to save!' }

  context 'as a student' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    def expect_question_contents_to_be_displayed
      activity_data.questions.each do |question|
        expect_question_prompt_to_be_displayed(question)
        expect_choices_to_be_displayed(question)
      end
    end

    def expect_question_prompt_to_be_displayed(question_data)
      question = from_true_false_enhanced_question(question_data.rank)
      expect_element_prompt_to_be_displayed(question, question_data.prompt)
    end

    def expect_choices_to_be_displayed(question_data)
      question = from_true_false_enhanced_question(question_data.rank)
      question_data.choices.each do |choice_data|
        choice = question.choice(choice_data.number)
        expect_element_prompt_to_be_displayed(choice, choice_data.prompt)
      end
    end

    scenario 'I can request help and reviews', nondeterministic: true do
      #ignoring_angular do
        direction_line_help_request_comment = 'a request help on the direction line'
        question_help_request_comment = 'some request help comment'

        visit section_activity_path(section.id, activity)
        for_preview_page(activity_data) do
          # Add an help request on the direction line
          {
            from_direction_line => direction_line_help_request_comment
          }.each do |item, item_comment|
            # insert 2 comments. The first one is a temporary one, it will be deleted
            comments = ['some temporary comment', item_comment]
            comments.each do |comment|
              validate_adding_instructor_help_request(
                item: item,
                comment: comment,
                helpable: [
                  from_direction_line
                ],
                non_helpable: [
                  # all the questions are not helpable
                  from_true_false_enhanced_question(1),
                  from_true_false_enhanced_question(2),
                  from_true_false_enhanced_question(3),
                  from_true_false_enhanced_question(4),
                  from_true_false_enhanced_question(5)
                ]
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

          from_true_false_enhanced_question(1).choice_true.select
          from_true_false_enhanced_question(2) do |question|
            question.choice_false.select
            question.correction.text = 'some correction for question 2'
          end
          from_true_false_enhanced_question(3).choice_true.select
          from_true_false_enhanced_question(4) do |question|
            question.choice_false.select
            question.correction.text = 'some correction for question 4'
          end
          from_true_false_enhanced_question(5) do |question|
            question.choice_false.select
            question.correction.text = 'some correction for question 5'
          end

          @page_object.button(:submit).click
        end

        for_submit_page(activity_data) do
          # help requests are displayed
          {
            from_direction_line => direction_line_help_request_comment
          }.each do |item, comment|
            expect_help_request_to_be_displayed(
              item: item, request_number: 1, comment: comment
            )
          end

          accept_alert do
            @page_object.button(:accept).click
          end
        end

        for_accept_page(activity_data) do
          # help requests are displayed
          {
            from_direction_line => direction_line_help_request_comment
          }.each do |item, comment|
            expect_help_request_to_be_displayed(
              item: item, request_number: 1, comment: comment
            )
          end

          # Request review: all the questions are not helpable
          validate_add_instructor_review_request_items_helpability(
            helpable: [
              # Questions that are incorrect should be helpable
              from_true_false_enhanced_question(4),
              from_true_false_enhanced_question(5)
            ],
            non_helpable: [
              from_direction_line,
              # Questions that are correct or pending should not be helpable
              from_true_false_enhanced_question(1),
              from_true_false_enhanced_question(2),
              from_true_false_enhanced_question(3)
            ]
          )

          # Add review requests for incorrect questions
          {
            from_true_false_enhanced_question(4) => 'review request for question 4',
            from_true_false_enhanced_question(5) => 'review request for question 5'
          }.each do |item, item_comment|
            validate_adding_instructor_review_request(
              item: item,
              comment: item_comment,
              helpable: [
                from_true_false_enhanced_question(4),
                from_true_false_enhanced_question(5)
              ],
              non_helpable: [
                from_direction_line,
                from_true_false_enhanced_question(1),
                from_true_false_enhanced_question(2),
                from_true_false_enhanced_question(3)
              ]
            )
            expect_review_request_to_be_displayed(
              item: item,
              request_number: 1,
              comment: item_comment
            )
          end
        end

        attempt = Attempt.active_attempt(student, section, activity)
        # Grade question 2 as correct
        question_data = activity_data.question(2)
        FeedbackItem.create!(
          attempt: attempt,
          points_earned: question_data.points_possible,
          question_label: format('question_%02d', question_data.rank),
          section: section,
          user: student
        )
        # Grade question 4 as partially correct
        question_data = activity_data.question(4)
        FeedbackItem.create!(
          attempt: attempt,
          points_earned: question_data.points_possible / 2.0,
          question_label: format('question_%02d', question_data.rank),
          section: section,
          user: student
        )
        # Keep question 5 as pending

        visit section_activity_path(section.id, activity)
        for_complete_page(activity_data) do
          # help requests are displayed
          {
            from_direction_line => direction_line_help_request_comment
          }.each do |item, comment|
            expect_help_request_to_be_displayed(
              item: item, request_number: 1, comment: comment
            )
          end

          with_element(from_true_false_enhanced_question(4).correction) do |item|
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
                  from_true_false_enhanced_question(4).correction
                ],
                non_helpable: [
                  from_direction_line,
                  from_true_false_enhanced_question(1),
                  from_true_false_enhanced_question(2),
                  from_true_false_enhanced_question(3),
                  from_true_false_enhanced_question(4),
                  from_true_false_enhanced_question(5),
                  # Correct answer is not helpable
                  from_true_false_enhanced_question(2).correction,
                  # Pending answer is not helpable
                  from_true_false_enhanced_question(5).correction
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
        end

        # Because the last request in this test is asynchronous, the test can
        # start tearing down the data (truncating activities table) before
        # the request completes, causing a validation error:
        # Validation failed: Activity must exist
        # Adding this bogus "visit" call prevents the teardown from starting
        # until after the help request is saved.
        visit section_activity_path(section.id, activity)
      #end
    end

    # Find a reliable way to replicate the failure that the save button
    # cannot be clicked.
    scenario 'I can complete a true false enhanced activity' do
      visit section_activity_path(section.id, activity)

      for_preview_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(3)

        (1..4).each do |qnum|
          from_true_false_enhanced_question(qnum) do |question|
            expect(question).to be_marked(:blank)
            expect(question.choices)
              .to all_be_marked(:blank)
              .and all_be_editable
          end
        end

        # Select question 1 as true (correct answer).
        # Select question 2 as true (incorrect answer).
        # Select question 3 as false (incorrect answer) and write a correction.
        # Select question 4 as false (correct answer) and write a correction.
        # Don't answer question 5.
        from_true_false_enhanced_question(1).choice_true.select
        from_true_false_enhanced_question(2).choice_true.select
        from_true_false_enhanced_question(3) do |question|
          question.choice_false.select
          question.correction.text = 'some correction for question 3'
        end
        from_true_false_enhanced_question(4) do |question|
          question.choice_false.select
          question.correction.text = 'some correction for question 4'
        end

        # Save without submitting
        click_save_button_expect_message(answers_saved_no_submitted_msg)
        expect_flash_message(:notice, 'Your changes have been saved.')
      end

      # Reload the page
      visit section_activity_path(section.id, activity)
      for_decide_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(3)

        # Every question should be marked as blank, choices marked as changed
        # and choices that were previously chosen and saved are already selected.
        # 'changed' means that the choice has been saved but not submitted.
        from_true_false_enhanced_question(1) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_marked(:changed).and all_be_editable
          expect(question.choice_true).to be_selected
          expect(question.correction).to not_exist
        end

        from_true_false_enhanced_question(2) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_marked(:changed).and all_be_editable
          expect(question.choice_true).to be_selected
          expect(question.correction).to not_exist
        end

        from_true_false_enhanced_question(3) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_marked(:changed).and all_be_editable
          expect(question.choice_false).to be_selected
          expect(question.correction).to exist
          expect(question.correction.text).to include('some correction for question 3')
        end

        from_true_false_enhanced_question(4) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_marked(:changed).and all_be_editable
          expect(question.choice_false).to be_selected
          expect(question.correction).to exist
          expect(question.correction.text).to include('some correction for question 4')
        end

        from_true_false_enhanced_question(5) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices)
            .to all_be_marked(:changed)
            .and all_be_editable
            .and all_be_unselected
          expect(question.correction).to not_exist
        end

        click_button_expect_alert(:submit, one_question_not_answered_msg)
      end

      for_submit_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        from_true_false_enhanced_question(1) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:correct)
          expect(question.choice_false).to be_marked(:blank)
        end

        from_true_false_enhanced_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:incorrect)
          expect(question.choice_false).to be_marked(:blank)
        end

        from_true_false_enhanced_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:incorrect)
          expect(question.correction.text).to include('some correction for question 3')
        end

        from_true_false_enhanced_question(4) do |question|
          expect(question).to be_marked(:pending)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:correct)
          expect(question.correction.text).to include('some correction for question 4')
        end

        from_true_false_enhanced_question(5) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_uneditable
        end

        scroll_to(@page_object.button(:retry))
        @page_object.button(:retry).click
      end

      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        from_true_false_enhanced_question(1) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:correct)
          expect(question.choice_false).to be_marked(:blank)
          expect(question.correction).to not_exist
        end

        from_true_false_enhanced_question(2) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_editable.and all_be_unselected
          expect(question.choice_true).to be_marked(:incorrect)
          expect(question.choice_false).to be_marked(:blank)
          expect(question.correction).to not_exist
        end

        from_true_false_enhanced_question(3) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_editable.and all_be_unselected
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:incorrect)
          expect(question.correction).to not_exist
        end

        from_true_false_enhanced_question(4) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_editable
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:correct).and be_selected
          expect(question.correction.text).to include('some correction for question 4')
        end

        from_true_false_enhanced_question(5) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_editable.and all_be_unselected
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:blank)
          expect(question.correction).to not_exist
        end

        # Correct question 2
        from_true_false_enhanced_question(2) do |question|
          question.choice_false.select
          question.correction.text = 'some correction for question 2'
        end

        # I correction question 3
        from_true_false_enhanced_question(3).choice_true.select

        # I change my correction for question 4
        from_true_false_enhanced_question(4).correction.text = \
          'La capital de Peru es Lima'

        click_save_button_expect_message(answers_saved_no_submitted_msg)
        expect_flash_message(:notice, 'Your changes have been saved.')
      end

      # Reload the page
      visit section_activity_path(section.id, activity)
      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        from_true_false_enhanced_question(1) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:correct)
          expect(question.choice_false).to be_marked(:blank)
          expect(question.correction).to not_exist
        end

        from_true_false_enhanced_question(2) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_marked(:changed)
          expect(question.choice_false).to be_selected
          expect(question.correction.text).to include('some correction for question 2')
        end

        from_true_false_enhanced_question(3) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices).to all_be_marked(:changed)
          expect(question.choice_true).to be_selected
          expect(question.correction).to not_exist
        end

        from_true_false_enhanced_question(4) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_selected.and be_marked(:correct)
          expect(question.correction.text).to include('La capital de Peru es Lima')
        end

        from_true_false_enhanced_question(5) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_editable
            .and all_be_unselected
        end

        # Save without making any changes should trigger a popup
        click_save_button_expect_message(no_changes_to_save_msg)

        # Submit the activity
        click_button_expect_alert(:submit, one_question_not_answered_msg)
      end

      for_submit_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(1)

        # Every question should be marked as correct or incorrect
        from_true_false_enhanced_question(1) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:correct)
          expect(question.choice_false).to be_marked(:blank)
        end

        from_true_false_enhanced_question(2) do |question|
          expect(question).to be_marked(:pending)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:correct)
          expect(question.correction.text).to include('some correction for question 2')
        end

        from_true_false_enhanced_question(3) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:correct)
          expect(question.choice_false).to be_marked(:blank)
        end

        from_true_false_enhanced_question(4) do |question|
          expect(question).to be_marked(:pending)
          expect(question.choices).to all_be_uneditable
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:correct)
          expect(question.correction.text).to include('La capital de Peru es Lima')
        end

        from_true_false_enhanced_question(5) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_uneditable
        end

        scroll_to(@page_object.button(:accept))
        click_button_expect_alert(:accept, 'You have chosen to accept your grade of 40.0%.')
      end

      expect_flash_message(:notice, 'Results finalized')

      for_accept_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed

        from_true_false_enhanced_question(1) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choice_true).to be_marked(:correct)
          expect(question.choice_false).to be_marked(:blank)
          expect(question.correction).to not_exist
        end

        from_true_false_enhanced_question(2) do |question|
          expect(question).to be_marked(:pending)
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:correct)
          expect(question.correction.text).to include('some correction for question 2')

          purpose 'I can show the sample answers' do
            question.sample_answers.show
            activity_data.question(2).sample_answers.each.with_index(1) do |answer, number|
              expect(question.sample_answers.answer(number).text).to eq(answer)
            end
          end
        end

        from_true_false_enhanced_question(3) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choice_true).to be_marked(:correct)
          expect(question.choice_false).to be_marked(:blank)
          expect(question.correction).to not_exist
        end

        from_true_false_enhanced_question(4) do |question|
          expect(question).to be_marked(:pending)
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:correct)
          expect(question.correction.text).to include('La capital de Peru es Lima')

          purpose 'I can show the sample answers' do
            question.sample_answers.show
            activity_data.question(4).sample_answers.each.with_index(1) do |answer, number|
              expect(question.sample_answers.answer(number).text).to eq(answer)
            end
          end
        end

        from_true_false_enhanced_question(5) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choice_true).to be_marked(:blank)
          expect(question.choice_false).to be_marked(:correction)
          expect(question.correction).to not_exist
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
      expect_flash_message(
        :notice,
        'Answer key mode. All correct answers will be displayed'
      )
    end
  end
end
