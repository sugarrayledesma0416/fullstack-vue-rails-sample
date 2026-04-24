shared_examples 'a student doing the fill in the blanks activity' do
  let(:cartridge_student?) { student.cartridge? }

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

  scenario 'I can use the accent bar to insert special characters' do
    visit student_path_to_activity
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

        # Switch to upper case & click all upper case buttons.
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
    # Question 2 will be correctly answered so we don't need a variable for it.
    question_3_wol_1 = nil
    # Question 4 will be kept blank so we don't need a variable for it.

    visit student_path_to_activity
    for_preview_page(activity_data) do
      expect_activity_shell_structure_to_be_complete
      expect_question_contents_to_be_displayed
      expect(page).to have_selector('.test-attempts-remaining', between: 1..2, text: '3')

      from_fib_question(1) do |question|
        expect(question.wol(1).input_field_text).to eq('')
        expect(question.wol(2).input_field_text).to eq('')
      end

      from_fib_question(2) do |question|
        expect(question.wol(1).input_field_text).to eq('')
      end

      from_fib_question(3) do |question|
        expect(question.wol(1).input_field_text).to eq('')
      end

      from_fib_question(4) do |question|
        expect(question.wol(1).input_field_text).to eq('')
      end

      # correct answer but with wrong punctuation
      question_1_wol_1 = 'answer, text 1.'
      # completely wrong
      question_1_wol_2 = 'completely wrong'

      from_fib_question(1).wol(1).choose_answer(question_1_wol_1)
      from_fib_question(1).wol(2).choose_answer(question_1_wol_2)

      click_save_button_expect_message(answers_saved_no_submitted_msg)
      expect_flash_message(:notice, 'Your changes have been saved.')
    end

    # Reload the page
    visit student_path_to_activity
    for_decide_page(activity_data) do
      expect_activity_shell_structure_to_be_complete
      expect_question_contents_to_be_displayed
      expect(page).to have_selector('.test-attempts-remaining', between: 1..2, text: '3')

      # Every question should be marked as changed
      # and wol previously answered and saved are already set
      from_fib_question(1) do |question|
        expect(question).to be_marked(:changed)
        expect(question.wol(1).input_field_text).to eq(question_1_wol_1)
        expect(question.wol(2).input_field_text).to eq(question_1_wol_2)
      end

      from_fib_question(2) do |question|
        expect(question).to be_marked(:changed)
        expect(question.wol(1).input_field_text).to eq('')
      end

      from_fib_question(3) do |question|
        expect(question).to be_marked(:changed)
        expect(question.wol(1).input_field_text).to eq('')
      end

      from_fib_question(4) do |question|
        expect(question).to be_marked(:changed)
        expect(question.wol(1).input_field_text).to eq('')
      end

      # answer correctly question 2 wol 1
      from_fib_question(2).wol(1).choose_answer('answer text 3')

      click_button_expect_alert(:submit, two_questions_not_answered_msg)
    end

    for_submit_page(activity_data) do
      expect_activity_shell_structure_to_be_complete
      expect_question_contents_to_be_displayed
      expect(page).to have_selector('.test-attempts-remaining', between: 1..2, text: '2')

      from_fib_question(1) do |question|
        expect(question).to be_marked(:incorrect)

        with_element(question.wol(1)) do |wol|
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', ',', 'text', '1', '.'])
          expect(wol.submitted_tokens.map(&:mark)). to eq(
            %i[none missed_punctuation none none missed_punctuation]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[none incorrect_or_extra_punctuation none none incorrect_or_extra_punctuation]
          )
        end

        with_element(question.wol(2)) do |wol|
          expect(wol.submitted_tokens.map(&:text)).to eq(['completely', 'wrong', ''])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[incorrect incorrect incorrect]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[incorrect_or_extra_word incorrect_or_extra_word missing_word]
          )
        end
      end

      from_fib_question(2) do |question|
        expect(question).to be_marked(:correct)

        with_element(question.wol(1)) do |wol|
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', 'text', '3'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none none])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none none none])
        end
      end

      from_fib_question(3) do |question|
        expect(question).to be_marked(:incorrect)

        with_element(question.wol(1)) do |wol|
          expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
        end
      end

      from_fib_question(4) do |question|
        expect(question).to be_marked(:incorrect)

        with_element(question.wol(1)) do |wol|
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
      expect(page).to have_selector('.test-attempts-remaining', between: 1..2, text: '2')

      from_fib_question(1) do |question|
        expect(question).to be_marked(:incorrect)

        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', ',', 'text', '1', '.'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[none missed_punctuation none none missed_punctuation]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[none incorrect_or_extra_punctuation none none incorrect_or_extra_punctuation]
          )
        end

        with_element(question.wol(2)) do |wol|
          expect(wol.input_field_text).to eq(question_1_wol_2)
          expect(wol.submitted_tokens.map(&:text)).to eq(['completely', 'wrong', ''])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[incorrect incorrect incorrect]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[incorrect_or_extra_word incorrect_or_extra_word missing_word]
          )
        end
      end

      from_fib_question(2) do |question|
        expect(question).to be_marked(:correct)

        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', 'text', '3'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none none])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none none none])
        end
      end

      from_fib_question(3) do |question|
        expect(question).to be_marked(:incorrect)
        with_element(question.wol(1)) do |wol|
          expect(wol.input_field_text).to eq('')
          expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
        end
      end

      from_fib_question(4) do |question|
        expect(question).to be_marked(:incorrect)
        with_element(question.wol(1)) do |wol|
          expect(wol.input_field_text).to eq('')
          expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
        end
      end

      # partially correct answer
      question_3_wol_1 = 'answer Text 4'
      from_fib_question(3).wol(1).choose_answer(question_3_wol_1)

      # and save without submitting
      click_save_button_expect_message(answers_saved_no_submitted_msg)
      expect_flash_message(:notice, 'Your changes have been saved.')
    end

    # Reload the page
    visit student_path_to_activity
    for_retry_page(activity_data) do
      expect_activity_shell_structure_to_be_complete
      expect_question_contents_to_be_displayed
      expect(page).to have_selector('.test-attempts-remaining', between: 1..2, text: '2')

      from_fib_question(1) do |question|
        expect(question).to be_marked(:incorrect)
        with_element(question.wol(1)) do |wol|
          # wol only has wrong punctuation and then should have no input field
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', ',', 'text', '1', '.'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[none missed_punctuation none none missed_punctuation]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[none incorrect_or_extra_punctuation none none incorrect_or_extra_punctuation]
          )
          expect(wol.correct_answer_tokens).to eq(['answer', 'text', '1'])
        end

        with_element(question.wol(2)) do |wol|
          # wol is incorrect and then should have an input field
          expect(wol.input_field_text).to eq(question_1_wol_2)
          expect(wol.submitted_tokens.map(&:text)).to eq(['completely', 'wrong', ''])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[incorrect incorrect incorrect]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[incorrect_or_extra_word incorrect_or_extra_word missing_word]
          )
        end
      end

      from_fib_question(2) do |question|
        expect(question).to be_marked(:correct)
        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', 'text', '3'])
          expect(wol.correct_answer_tokens).to eq(['answer', 'text', '3'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none none])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none none none])
        end
      end

      from_fib_question(3) do |question|
        expect(question).to be_marked(:incorrect)
        with_element(question.wol(1)) do |wol|
          expect(wol.input_field_text).to eq(question_3_wol_1)
          expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
        end
      end

      from_fib_question(4) do |question|
        expect(question).to be_marked(:incorrect)
        with_element(question.wol(1)) do |wol|
          expect(wol.input_field_text).to eq('')
          expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
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
      expect(page).to have_selector('.test-attempts-remaining', between: 1..2, text: '1')

      from_fib_question(1) do |question|
        expect(question).to be_marked(:incorrect)

        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', ',', 'text', '1', '.'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[none missed_punctuation none none missed_punctuation]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[none incorrect_or_extra_punctuation none none incorrect_or_extra_punctuation]
          )
        end

        with_element(question.wol(2)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['completely', 'wrong', ''])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[incorrect incorrect incorrect]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[incorrect_or_extra_word incorrect_or_extra_word missing_word]
          )
        end
      end

      from_fib_question(2) do |question|
        expect(question).to be_marked(:correct)
        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', 'text', '3'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none none])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none none none])
        end
      end

      from_fib_question(3) do |question|
        expect(question).to be_marked(:correct)
        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', 'T', 'e', 'x', 't', '4'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[none incorrect none none none none]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[none incorrect_accent_or_capitalization none none none none]
          )
        end
      end

      from_fib_question(4) do |question|
        expect(question).to be_marked(:incorrect)
        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
        end
      end

      click_button_expect_alert(:accept, 'You have chosen to accept your grade of 60.0%.')
    end

    for_accept_page(activity_data) do
      expect_activity_shell_structure_to_be_complete
      expect_question_contents_to_be_displayed

      from_fib_question(1) do |question|
        expect(question).to be_marked(:partial)

        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', ',', 'text', '1', '.'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[none missed_punctuation none none missed_punctuation]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[none incorrect_or_extra_punctuation none none incorrect_or_extra_punctuation]
          )
          expect(wol.correct_answer_tokens).to eq(['answer', 'text', '1'])
        end

        with_element(question.wol(2)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['completely', 'wrong', ''])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[incorrect incorrect incorrect]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[incorrect_or_extra_word incorrect_or_extra_word missing_word]
          )
          expect(wol.correct_answer_tokens).to eq(['answer', 'text', '2'])
          expect(wol.best_answers).to eq([
            'or',
            'another answer 2'
          ])
        end
      end

      from_fib_question(2) do |question|
        expect(question).to be_marked(:correct)
        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', 'text', '3'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none none])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none none none])
          expect(wol.correct_answer_tokens).to eq(['answer', 'text', '3'])
        end
      end

      from_fib_question(3) do |question|
        expect(question).to be_marked(:correct)
        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['answer', 'T', 'e', 'x', 't', '4'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(
            %i[none incorrect none none none none]
          )
          expect(wol.submitted_tokens.map(&:title)).to eq(
            %i[none incorrect_accent_or_capitalization none none none none]
          )
          expect(wol.correct_answer_tokens).to eq(['answer', 'text', '4'])
        end
      end

      from_fib_question(4) do |question|
        expect(question).to be_marked(:incorrect)
        with_element(question.wol(1)) do |wol|
          expect(wol).to have_no_input_field
          expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
          expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
          expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
          # When the student answered nothing, there is no correct answer but a best answer
          expect(wol.best_answers).to eq(['answer text 5'])
        end
      end
    end
  end
end

shared_examples 'an instructor seeing a fill in the blanks activity' do
  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    visit instructor_path_to_activity
  end

  scenario 'I can see answer key' do
    click_link('Answer key')
    expect(page).to have_selector('.test-flash-notice',
                                  text: 'Answer key mode. All correct answers will be displayed')
  end
end
