def create_fill_in_the_blanks_table_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'fill_in_the_blanks_table.xml'),
    program,
    grading_method: 'auto'
  )
end

feature 'Fill in the blanks table activity', js: true, chrome: true, new_gb_sync: true do
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

  let(:activity) { create_fill_in_the_blanks_table_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::FillInTheBlanks.new(activity, media_items) }
  let(:fake_submissions) { {} }
  let(:answers_saved_no_submitted_msg) do
    'Your answers will be SAVED. They will NOT be submitted for a grade.'
  end
  let(:two_questions_not_answered_msg) { '2 questions are unanswered.' }
  let(:three_questions_not_answered_msg) { '3 questions are unanswered.' }
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
        question = from_fib_question(question_data.rank)
        expect_element_prompt_to_be_displayed(question, question_data.prompt)
      end
    end

    scenario 'I can request help and reviews', nondeterministic: true do
      ignoring_angular do
        direction_line_help_request_comment = 'a request help on the direction line'
        question_help_request_comment = 'some request help comment'

        visit section_activity_path(section.id, activity)
        for_preview_page(activity_data) do
          # Add an help request on the direction line and on a question
          { from_direction_line => direction_line_help_request_comment,
            from_fib_question(1) => question_help_request_comment }.each do |item, item_comment|
            # insert 2 comments. The first one is a temporary one, it will be deleted
            comments = ['some temporary comment', item_comment]
            comments.each do |comment|
              question = from_fib_question(1)
              validate_adding_instructor_help_request(
                item: item,
                comment: comment,
                helpable: [
                  from_direction_line,
                  # whole questions are helpable
                  question
                ],
                non_helpable: [
                  # wol are not helpable
                  question.wol(1),
                  question.wol(2),
                  question.wol(3),
                  question.wol(4),
                  question.wol(5),
                  question.wol(6)
                ]
              )
            end
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[0])
            expect_help_request_to_be_displayed(item: item, request_number: 2, comment: comments[1])
            remove_help_request(item: item, request_number: 1)
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[1])
          end

          # correct answer but with incorrect accent
          from_fib_question(1).wol(1).choose_answer('Què')
          # wrong answer
          from_fib_question(1).wol(2).choose_answer('despedidas')
          # correct answer
          from_fib_question(1).wol(3).choose_answer('Hasta')

          click_button_expect_alert(:submit, three_questions_not_answered_msg)
        end

        for_submit_page(activity_data) do
          # help requests are displayed
          { from_direction_line => direction_line_help_request_comment,
            from_fib_question(1) => question_help_request_comment }.each do |item, comment|
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comment)
          end

          click_button_expect_alert(:accept, 'You have chosen to accept your grade of 16.7%')
        end

        for_accept_page(activity_data) do
          # help requests are displayed
          { from_direction_line => direction_line_help_request_comment,
            from_fib_question(1) => question_help_request_comment }.each do |item, comment|
            expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comment)
          end

          # Request review
          with_element(from_fib_question(1).wol(2)) do |item|
            comments = ['some request review comment', 'another request review comment']
            comments.each do |comment|
              question = from_fib_question(1)
              validate_adding_instructor_review_request(
                item: item,
                comment: comment,
                helpable: [
                  # incorrect questions are helpable
                  question.wol(1),
                  question.wol(2)
                ],
                non_helpable: [
                  from_direction_line,
                  # whole questions are not helpable
                  question,
                  # correct and blank answers are not helpable
                  question.wol(3),
                  question.wol(4),
                  question.wol(5),
                  question.wol(6)
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

    scenario 'I can use the accent bar to insert special characters' do
      visit section_activity_path(section.id, activity)
      for_preview_page(activity_data) do
        with_element(from_fib_question(1).wol(1)) do |wol|
          str = 'blah'
          # set initial answer (it's used to focus the input field)
          wol.choose_answer(str)

          # Open Accent bar modal for the current input.
          page.find('#question_01_wol_1').click
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
          expect(wol.input_field_text).to eq(str)
        end
      end
    end

    scenario 'I can do a fill in the blanks activity' do
      question_1_wol_1 = nil
      question_1_wol_2 = nil
      question_3_wol_1 = nil

      visit section_activity_path(section.id, activity)
      for_preview_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(3)

        from_fib_question(1) do |question|
          expect(question.wol(1).input_field_text).to eq('')
          expect(question.wol(2).input_field_text).to eq('')
          expect(question.wol(3).input_field_text).to eq('')
          expect(question.wol(4).input_field_text).to eq('')
          expect(question.wol(5).input_field_text).to eq('')
          expect(question.wol(6).input_field_text).to eq('')

          # correct answer but with incorrect accent
          question_1_wol_1 = 'Què'
          # completly wrong
          question_1_wol_2 = 'Las despedidas'

          question.wol(1).choose_answer(question_1_wol_1)
          question.wol(2).choose_answer(question_1_wol_2)
        end

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
        # and wol previously answered and saved are already set
        from_fib_question(1) do |question|
          expect(question).to be_marked(:changed)
          expect(question.wol(1).input_field_text).to eq(question_1_wol_1)
          expect(question.wol(2).input_field_text).to eq(question_1_wol_2)
          expect(question.wol(3).input_field_text).to eq('')
          expect(question.wol(4).input_field_text).to eq('')
          expect(question.wol(5).input_field_text).to eq('')
          expect(question.wol(6).input_field_text).to eq('')

          # answer correctly
          question.wol(3).choose_answer('Hasta')
        end

        click_button_expect_alert(:submit, three_questions_not_answered_msg)
      end

      for_submit_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        from_fib_question(1) do |question|
          expect(question).to be_marked(:incorrect)

          with_element(question.wol(1)) do |wol|
            expect(wol.submitted_tokens.map(&:text)).to eq(['Q', 'u', 'è'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[none none incorrect_accent_or_capitalization]
            )
          end

          with_element(question.wol(2)) do |wol|
            expect(wol.submitted_tokens.map(&:text)).to eq(['Las', 'despedidas'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[incorrect_or_extra_word incorrect_or_extra_word]
            )
          end

          with_element(question.wol(3)) do |wol|
            expect(wol.submitted_tokens.map(&:text)).to eq(['Hasta'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(4)) do |wol|
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(5)) do |wol|
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(6)) do |wol|
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end
        end

        @page_object.button(:retry).click
      end

      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed
        expect(@page_object.attempts.remaining).to eq(2)

        from_fib_question(1) do |question|
          expect(question).to be_marked(:incorrect)

          with_element(question.wol(1)) do |wol|
            expect(wol.input_field_text).to eq('Què')
            expect(wol.submitted_tokens.map(&:text)).to eq(['Q', 'u', 'è'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[none none incorrect_accent_or_capitalization]
            )
          end

          with_element(question.wol(2)) do |wol|
            expect(wol.input_field_text).to eq('Las despedidas')
            expect(wol.submitted_tokens.map(&:text)).to eq(['Las', 'despedidas'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[incorrect_or_extra_word incorrect_or_extra_word]
            )
          end

          with_element(question.wol(3)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Hasta'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(4)) do |wol|
            expect(wol.input_field_text).to eq('')
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(5)) do |wol|
            expect(wol.input_field_text).to eq('')
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(6)) do |wol|
            expect(wol.input_field_text).to eq('')
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end
        end

        # partially correct answer
        from_fib_question(1).wol(4).choose_answer('Cómo, estás')

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

        from_fib_question(1) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.wol(1)) do |wol|
            expect(wol.input_field_text).to eq('Què')
            expect(wol.submitted_tokens.map(&:text)).to eq(['Q', 'u', 'è'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[none none incorrect_accent_or_capitalization]
            )
          end

          with_element(question.wol(2)) do |wol|
            expect(wol.input_field_text).to eq('Las despedidas')
            expect(wol.submitted_tokens.map(&:text)).to eq(['Las', 'despedidas'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[incorrect_or_extra_word incorrect_or_extra_word]
            )
          end

          with_element(question.wol(3)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Hasta'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(4)) do |wol|
            expect(wol.input_field_text).to eq('Cómo, estás')
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(5)) do |wol|
            expect(wol.input_field_text).to eq('')
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(6)) do |wol|
            expect(wol.input_field_text).to eq('')
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
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

        from_fib_question(1) do |question|
          expect(question).to be_marked(:incorrect)
          with_element(question.wol(1)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Q', 'u', 'è'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[none none incorrect_accent_or_capitalization]
            )
          end

          with_element(question.wol(2)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Las', 'despedidas'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[incorrect_or_extra_word incorrect_or_extra_word]
            )
          end

          with_element(question.wol(3)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Hasta'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(4)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Cómo', ',', 'estás'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect missed_punctuation incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[incorrect_or_extra_word incorrect_or_extra_punctuation incorrect_or_extra_word]
            )
          end

          with_element(question.wol(5)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end

          with_element(question.wol(6)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          end
        end

        click_button_expect_alert(:accept, 'You have chosen to accept your grade of 16.7%.')
      end

      for_accept_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_question_contents_to_be_displayed

        from_fib_question(1) do |question|
          expect(question).to be_marked(:partial)

          with_element(question.wol(1)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Q', 'u', 'è'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[none none incorrect_accent_or_capitalization]
            )
            expect(wol.correct_answer_tokens).to eq(['Qué'])
          end

          with_element(question.wol(2)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Las', 'despedidas'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[incorrect_or_extra_word incorrect_or_extra_word]
            )
            expect(wol.correct_answer_tokens).to eq(['saludos', '', ''])
            expect(wol.best_answers).to eq([
              'or',
              'Saludos',
              'Saludo',
              'saludo'
            ])
          end

          with_element(question.wol(3)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Hasta'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
            expect(wol.correct_answer_tokens).to eq(['Hasta'])
          end

          with_element(question.wol(4)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['Cómo', ',', 'estás'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect missed_punctuation incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(
              %i[incorrect_or_extra_word incorrect_or_extra_punctuation incorrect_or_extra_word]
            )
            expect(wol.correct_answer_tokens).to eq(['despedidas', '', ''])
            expect(wol.best_answers).to eq([
              'or',
              'Despedidas',
              'Despedida',
              'despedida'
            ])
          end

          with_element(question.wol(5)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
            # When the student answered nothing, there is no correct answer but a best answer
            expect(wol.best_answers).to eq(['Mucho'])
          end

          with_element(question.wol(6)) do |wol|
            expect(wol).to have_no_input_field
            expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
            expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
            expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
            # When the student answered nothing, there is no correct answer but a best answer
            expect(wol.best_answers).to eq(['presentaciones'])
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
