feature 'Multiple choice activity', js: true, chrome: true, new_gb_sync: true do
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

  let(:choice_media_item) { create(:media_item_image, filename: 'unit1_thumbnail.png') }

  let(:choice_media_link) { MediaLink.new(desired_media_item_id: choice_media_item.id) }

  def add_image_to_choice(activity, question_index, choice_index)
    activity.questions[question_index].choices[choice_index].image = choice_media_link
    activity_data.questions[question_index].choices[choice_index].image = choice_media_link
  end

  let(:activity) { create_multiple_choice_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::MultipleChoice.new(activity, media_items) }
  let(:fake_submissions) { {} }
  let(:answers_saved_no_submitted_msg) do
    'Your answers will be SAVED. They will NOT be submitted for a grade.'
  end
  let(:one_question_not_answered_msg) { '1 question is unanswered.' }
  let(:two_questions_not_answered_msg) { '2 questions are unanswered.' }
  let(:no_changes_to_save_msg) { 'No changes to save!' }

  context 'as a student' do
    before do
      initialize_fake_submissions_client
      add_image_to_choice(activity, 0, 2)
      allow_any_instance_of(
        Activity.const_get(:ActiveRecord_Relation)
      ).to receive(:find).with(activity.id.to_s).and_return(activity)
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
      question = from_multiple_choice_question(question_data.rank)
      expect_element_prompt_to_be_displayed(question, question_data.prompt)
    end

    def expect_choices_to_be_displayed(question_data)
      question = from_multiple_choice_question(question_data.rank)
      question_data.choices.each do |choice_data|
        choice = question.choice(choice_data.number)
        expect_element_prompt_to_be_displayed(choice, choice_data.prompt)
        expect_choice_image_to_be_displayed(choice_data.image) if choice_data.image
      end
    end

    def expect_choice_image_to_be_displayed(image)
      expect(page).to have_selector(
        ".test-choice-image img[src='#{image.media_item.public_filename}']"
      )
    end

    scenario 'I can request help and reviews', nondeterministic: true do
      ignoring_angular do
        direction_line_help_request_comment = 'a request help on the direction line'
        question_help_request_comment = 'some request help comment'

        visit section_activity_path(section.id, activity)
        for_preview_page(activity_data) do
          # Add an help request on the direction line and on a question
          { from_direction_line => direction_line_help_request_comment,
            from_multiple_choice_question(1) => question_help_request_comment }.each do |item, item_comment|
            # insert 2 comments. The first one is a temporary one, it will be deleted
            comments = ['some temporary comment', item_comment]
            comments.each do |comment|
              validate_adding_instructor_help_request(
                item: item,
                comment: comment,
                helpable: [
                  from_direction_line,
                  # whole questions are helpable
                  from_multiple_choice_question(1),
                  from_multiple_choice_question(2),
                  from_multiple_choice_question(3),
                  from_multiple_choice_question(4)
                ],
                non_helpable: []
              )
            end
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[0])
            expect_help_request_to_be_displayed(item: item, request_number: 2, comment: comments[1])
            remove_help_request(item: item, request_number: 1)
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[1])
          end

          # Answer correctly question 1, incorrectly questions 2 and 3
          # and don't answer question 4
          question_1_choice = activity_data.question(1).correct_choice
          question_2_choice = activity_data.question(2).incorrect_choices.first
          question_3_choice = activity_data.question(3).incorrect_choices.first

          [question_1_choice, question_2_choice, question_3_choice].each.with_index(1) do |choice, qnum|
            from_multiple_choice_question(qnum).select_choice(choice)
          end

          accept_alert do
            @page_object.button(:submit).click
          end
        end

        for_submit_page(activity_data) do
          # help requests are displayed
          { from_direction_line => direction_line_help_request_comment,
            from_multiple_choice_question(1) => question_help_request_comment }.each do |item, comment|
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comment)
          end

          accept_alert do
            @page_object.button(:accept).click
          end
        end

        for_accept_page(activity_data) do
          # help requests are displayed
          { from_direction_line => direction_line_help_request_comment,
            from_multiple_choice_question(1) => question_help_request_comment }.each do |item, comment|
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comment)
          end

          # Request review
          from_multiple_choice_question(3) do |item|
            comments = ['some request review comment', 'another request review comment']
            comments.each do |comment|
              validate_adding_instructor_review_request(
                item: item,
                comment: comment,
                helpable: [
                  # incorrect questions are helpable
                  from_multiple_choice_question(2),
                  from_multiple_choice_question(3)
                ],
                non_helpable: [
                  from_direction_line,
                  # correct and blank questions are not helpable
                  from_multiple_choice_question(1),
                  from_multiple_choice_question(4)
                ]
              )
            end
            expect_review_request_to_be_displayed(item: item, request_number: 1, comment: comments[0])
            expect_review_request_to_be_displayed(item: item, request_number: 2, comment: comments[1])
            remove_review_request(item: item, request_number: 1)
            expect_review_request_to_be_displayed(item: item, request_number: 1, comment: comments[1])
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
    end

    scenario 'I can do a multiple choice activity' do
      question_1_choice = nil
      question_2_choice = nil
      question_3_choice = nil

      visit section_activity_path(section.id, activity)

      for_preview_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(3)

        (1..4).each do |qnum|
          from_multiple_choice_question(qnum) do |question|
            expect(question).to be_marked(:blank)
            expect(question.choices)
              .to all_be_marked(:blank)
              .and all_be_editable
          end
        end

        # Answer correctly question 1, incorrectly questions 2 and 3
        # and don't answer question 4
        question_1_choice = activity_data.question(1).correct_choice
        question_2_choice = activity_data.question(2).incorrect_choices.first
        question_3_choice = activity_data.question(3).incorrect_choices.first

        from_multiple_choice_question(1).select_choice(question_1_choice)
        from_multiple_choice_question(2).select_choice(question_2_choice)
        from_multiple_choice_question(3).select_choice(question_3_choice)

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

        # Every question should be marked as changed and choices that were
        # previously chosen and saved are already selected
        # `changed` means that the question has been saved but not submitted.
        [question_1_choice, question_2_choice, question_3_choice].each.with_index(1) do |choice, qnum|
          from_multiple_choice_question(qnum) do |question|
            expect(question).to be_marked(:changed)
            expect(question.choices)
              .to all_be_marked(:changed)
              .and all_be_editable
            expect(question.choice(choice)).to be_selected
          end
        end

        from_multiple_choice_question(4) do |question|
          expect(question).to be_marked(:changed)
          expect(question.choices)
            .to all_be_marked(:changed)
            .and all_be_editable
            .and all_be_unselected
        end

        click_button_expect_alert(:submit, one_question_not_answered_msg)
      end

      for_submit_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        # Every question should be marked as correct or incorrect
        from_multiple_choice_question(1) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_1_choice => :correct)
            .and all_be_uneditable
        end
        from_multiple_choice_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_2_choice => :incorrect)
            .and all_be_uneditable
        end
        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_3_choice => :incorrect)
            .and all_be_uneditable
        end
        from_multiple_choice_question(4) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_uneditable
        end

        @page_object.button(:retry).click
      end

      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        # Every question should be marked as correct or incorrect
        from_multiple_choice_question(1) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_1_choice => :correct)
            .and all_be_uneditable
        end
        from_multiple_choice_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_2_choice => :incorrect)
            .and all_be_editable
            .and all_be_unselected
        end
        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_3_choice => :incorrect)
            .and all_be_editable
            .and all_be_unselected
        end
        from_multiple_choice_question(4) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_editable
            .and all_be_unselected
        end

        # Correct question 2 and choose a different incorrect choice for question 3
        question_2_choice = activity_data.question(2).correct_choice
        question_3_choice = activity_data.question(3).incorrect_choices[1]
        from_multiple_choice_question(2).select_choice(question_2_choice)
        from_multiple_choice_question(3).select_choice(question_3_choice)

        click_save_button_expect_message(answers_saved_no_submitted_msg)
        expect_flash_message(:notice, 'Your changes have been saved.')
      end

      # Reload the page
      visit section_activity_path(section.id, activity)
      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        # Every question should be marked as correct or incorrect except the
        # question I changed and saved should be marked as change
        from_multiple_choice_question(1) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_1_choice => :correct)
            .and all_be_uneditable
        end
        from_multiple_choice_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:changed)
            .and all_be_editable
          expect(question.choice(question_2_choice)).to be_selected
        end
        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:changed)
            .and all_be_editable
          expect(question.choice(question_3_choice)).to be_selected
        end
        from_multiple_choice_question(4) do |question|
          expect(question).to be_marked(:incorrect)
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
        from_multiple_choice_question(1) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_1_choice => :correct)
            .and all_be_uneditable
        end
        from_multiple_choice_question(2) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_2_choice => :correct)
            .and all_be_uneditable
        end
        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_3_choice => :incorrect)
            .and all_be_uneditable
        end
        from_multiple_choice_question(4) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_uneditable
        end

        click_button_expect_alert(:accept, 'You have chosen to accept your grade of 50.0%.')
      end

      for_accept_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed

        # Every question should be marked as correct or incorrect
        from_multiple_choice_question(1) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_1_choice => :correct)
            .and all_be_uneditable
        end
        from_multiple_choice_question(2) do |question|
          expect(question).to be_marked(:correct)
          expect(question.choices)
            .to all_be_marked(:blank).except(question_2_choice => :correct)
            .and all_be_uneditable
        end
        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank)
            .except(
              question_3_choice => :incorrect,
              activity_data.question(3).correct_choice => :correction
            )
            .and all_be_uneditable
        end
        from_multiple_choice_question(4) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank)
            .except(activity_data.question(4).correct_choice => :correction)
            .and all_be_uneditable
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
      expect(page).to have_selector(
        '.test-flash-notice',
        text: 'Answer key mode. All correct answers will be displayed'
      )
    end
  end
end
