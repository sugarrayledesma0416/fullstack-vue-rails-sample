def create_drop_down_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'dropdown.xml'),
    program,
    grading_method: 'auto'
  )
end

feature 'Drop down activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include CapybaraViewHelpers
  include ActivityTest::Helpers

  let(:blank_indicator) { '(blank)' }
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
  let!(:media_items) do
    Array.new(4) do |i|
      id = i + 1
      create(:media_item_image, filename: "multiple_choice_prompt_#{id}.gif")
    end
  end
  let(:activity) { create_drop_down_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::DropDown.new(activity, media_items) }
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
      activity_data.questions.each do |question_data|
        question = from_drop_down_question(question_data.rank)
        expect_element_prompt_to_be_displayed(question, question_data.prompt)
      end
    end

    scenario 'I can request help and reviews', nondeterministic: true do
      ignoring_angular do
        direction_line_help_request_comment = 'request help on the direction line'
        question_help_request_comment = 'some request help comment'

        visit section_activity_path(section.id, activity)
        for_preview_page(activity_data) do
          # Add help requests on the direction line and on a question
          { from_direction_line => direction_line_help_request_comment,
            from_drop_down_question(1) => question_help_request_comment }.each do |item, item_comment|
            # insert 2 comments. The first one is a temporary one, it will be deleted
            comments = ['some temporary comment', item_comment]
            comments.each do |comment|
              validate_adding_instructor_help_request(
                item: item,
                comment: comment,
                helpable: [
                  from_direction_line,
                  # whole questions are helpable
                  from_drop_down_question(1),
                  from_drop_down_question(2),
                  from_drop_down_question(3)
                ],
                non_helpable: [
                  # answers are not helpable
                  from_drop_down_question(1).drop_down_menu(1),
                  from_drop_down_question(2).drop_down_menu(1),
                  from_drop_down_question(2).drop_down_menu(2),
                  from_drop_down_question(3).drop_down_menu(1)
                ]
              )
            end
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[0])
            expect_help_request_to_be_displayed(item: item, request_number: 2, comment: comments[1])
            remove_help_request(item: item, request_number: 1)
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[1])
          end

          # Answer correctly menu 1.1 and incorrectly menu 2.1 and menu 3.1
          # and don't answer other menus
          question_1_menu_1_option = activity_data.question(1).menu(1).correct_option
          question_2_menu_1_option = activity_data.question(2).menu(1).incorrect_options[0]
          question_3_menu_1_option = activity_data.question(3).menu(1).incorrect_options[0]

          from_drop_down_question(1).drop_down_menu(1).select_option(question_1_menu_1_option.number)
          from_drop_down_question(2).drop_down_menu(1).select_option(question_2_menu_1_option.number)
          from_drop_down_question(3).drop_down_menu(1).select_option(question_3_menu_1_option.number)

          accept_alert do
            @page_object.button(:submit).click
          end
        end

        for_submit_page(activity_data) do
          # help requests are displayed
          { from_direction_line => direction_line_help_request_comment,
            from_drop_down_question(1) => question_help_request_comment }.each do |item, comment|
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comment)
          end

          accept_alert do
            @page_object.button(:accept).click
          end
        end

        for_accept_page(activity_data) do
          # help requests are displayed
          { from_direction_line => direction_line_help_request_comment,
            from_drop_down_question(1) => question_help_request_comment }.each do |item, comment|
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comment)
          end

          # Review request
          with_element(from_drop_down_question(3).drop_down_menu(1)) do |item|
            comments = ['some request review comment', 'another request review comment']
            comments.each do |comment|
              validate_adding_instructor_review_request(
                item: item,
                comment: comment,
                helpable: [
                  # incorrect answers are helpable
                  from_drop_down_question(2).drop_down_menu(1),
                  from_drop_down_question(3).drop_down_menu(1)
                ],
                non_helpable: [
                  from_direction_line,
                  # whole questions are not helpable
                  from_drop_down_question(1),
                  from_drop_down_question(2),
                  from_drop_down_question(3),
                  # correct and blank answers are not helpable
                  from_drop_down_question(1).drop_down_menu(1),
                  from_drop_down_question(2).drop_down_menu(2)
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

    scenario 'I can do a drop down activity' do
      question_1_menu_1_option = nil
      question_2_menu_1_option = nil
      question_3_menu_1_option = nil

      visit section_activity_path(section.id, activity)

      for_preview_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(3)

        from_drop_down_question(1) do |question|
          expect(question).to be_marked(:blank)
          expect(question.drop_down_menu(1).options).to all_be_unselected
        end

        from_drop_down_question(2) do |question|
          expect(question).to be_marked(:blank)
          expect(question.drop_down_menu(1).options).to all_be_unselected
          expect(question.drop_down_menu(2).options).to all_be_unselected
        end

        from_drop_down_question(3) do |question|
          expect(question).to be_marked(:blank)
          expect(question.drop_down_menu(1).options).to all_be_unselected
        end

        # Answer correctly menu 1.1 and incorrectly menu 2.1 and menu 3.1
        # and don't answer other menus
        question_1_menu_1_option = activity_data.question(1).menu(1).correct_option
        question_2_menu_1_option = activity_data.question(2).menu(1).incorrect_options[0]
        question_3_menu_1_option = activity_data.question(3).menu(1).incorrect_options[0]

        from_drop_down_question(1).drop_down_menu(1).select_option(question_1_menu_1_option.number)
        from_drop_down_question(2).drop_down_menu(1).select_option(question_2_menu_1_option.number)
        from_drop_down_question(3).drop_down_menu(1).select_option(question_3_menu_1_option.number)

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
        from_drop_down_question(1) do |question|
          expect(question).to be_marked(:changed)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:changed)
            expect(menu.option(question_1_menu_1_option.number)).to be_selected
          end
        end

        from_drop_down_question(2) do |question|
          expect(question).to be_marked(:changed)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:changed)
            expect(menu.option(question_2_menu_1_option.number)).to be_selected
          end
          with_element(question.drop_down_menu(2)) do |menu|
            expect(menu).to be_marked(:changed)
            expect(menu.options).to all_be_unselected
          end
        end

        from_drop_down_question(3) do |question|
          expect(question).to be_marked(:changed)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:changed)
            expect(menu.option(question_3_menu_1_option.number)).to be_selected
          end
        end

        click_button_expect_alert(:submit, one_question_not_answered_msg)
      end

      for_submit_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        # Every question should be marked as correct or incorrect
        from_drop_down_question(1) do |question|
          expect(question).to be_marked(:correct)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:correct)
            expect(menu.text).to include(question_1_menu_1_option.text)
          end
        end

        from_drop_down_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.text).to include(question_2_menu_1_option.text)
          end
          with_element(question.drop_down_menu(2)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.text).to include(blank_indicator)
          end
        end

        from_drop_down_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.text).to include(question_3_menu_1_option.text)
          end
        end

        @page_object.button(:retry).click
      end

      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        # Every question should be marked as correct or incorrect
        from_drop_down_question(1) do |question|
          expect(question).to be_marked(:correct)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:correct)
            expect(menu.text).to include(question_1_menu_1_option.text)
          end
        end

        from_drop_down_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.option(question_2_menu_1_option.number)).to be_selected
          end
          with_element(question.drop_down_menu(2)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.options).to all_be_unselected
          end
        end

        from_drop_down_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.option(question_3_menu_1_option.number)).to be_selected
          end
        end

        # Correct question 2, menu 1
        question_2_menu_1_option = activity_data.question(2).menu(1).correct_option
        from_drop_down_question(2).drop_down_menu(1).select_option(question_2_menu_1_option.number)

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

        from_drop_down_question(1) do |question|
          expect(question).to be_marked(:correct)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:correct)
            expect(menu.text).to include(question_1_menu_1_option.text)
          end
        end

        from_drop_down_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:changed)
            expect(menu.option(question_2_menu_1_option.number)).to be_selected
          end
          with_element(question.drop_down_menu(2)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.options).to all_be_unselected
          end
        end

        from_drop_down_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.option(question_3_menu_1_option.number)).to be_selected
          end
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
        from_drop_down_question(1) do |question|
          expect(question).to be_marked(:correct)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:correct)
            expect(menu.text).to include(question_1_menu_1_option.text)
          end
        end

        from_drop_down_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:correct)
            expect(menu.text).to include(question_2_menu_1_option.text)
          end
          with_element(question.drop_down_menu(2)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.text).to include(blank_indicator)
          end
        end

        from_drop_down_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.text).to include(question_3_menu_1_option.text)
          end
        end

        click_button_expect_alert(:accept, 'You have chosen to accept your grade of 50.0%.')
      end

      for_accept_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed

        # Every question should be marked as correct or incorrect
        from_drop_down_question(1) do |question|
          expect(question).to be_marked(:correct)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:correct)
            expect(menu.text).to eq(question_1_menu_1_option.text)
          end
        end

        from_drop_down_question(2) do |question|
          expect(question).to be_marked(:partial)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:correct)
            expect(menu.text).to include(question_2_menu_1_option.text)
          end
          with_element(question.drop_down_menu(2)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.text).to include(blank_indicator)
          end
        end

        from_drop_down_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.drop_down_menu(1)) do |menu|
            expect(menu).to be_marked(:incorrect)
            expect(menu.text).to include(question_3_menu_1_option.text)
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
      expect(page).to have_selector('.test-flash-notice',
                                    text: 'Answer key mode. All correct answers will be displayed')
    end
  end
end
