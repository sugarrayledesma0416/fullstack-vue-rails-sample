def create_multi_type_with_oe_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'multi_type_with_oe.xml'),
    program,
    grading_method: 'auto'
  )
end

feature 'Multi type activity', js: true, chrome: true, new_gb_sync: true, retry: 2 do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:category) { create(:category, course: course, penalty_percent: 0) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let!(:media_items) do
    Array.new(4) do |i|
      id = i + 1
      create(:media_item_image, filename: "multiple_choice_prompt_#{i + 1}.gif")
    end
  end
  let(:activity) { create_multi_type_with_oe_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::MultiType.new(activity, media_items) }
  let(:fake_submissions) { {} }
  let(:answers_saved_no_submitted_msg) do
    'Your answers will be SAVED. They will NOT be submitted for a grade.'
  end
  let(:three_questions_not_answered_msg) { '3 questions are unanswered.' }
  let(:four_questions_not_answered_msg) { '4 questions are unanswered.' }
  let(:no_changes_to_save_msg) { 'No changes to save!' }

  context 'as a student' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    def expect_multiple_choice_question_contents_to_be_displayed(activity_data)
      activity_data.questions.each do |question_data|
        question = from_multiple_choice_question(question_data.rank)
        expect_element_prompt_to_be_displayed(question, question_data.prompt)

        question_data.choices.each do |choice_data|
          choice = question.choice(choice_data.number)
          expect_element_prompt_to_be_displayed(choice, choice_data.prompt)
        end
      end
    end

    def expect_open_ended_question_contents_to_be_displayed(activity_data)
      activity_data.questions.each do |question_data|
        question = from_open_ended_question(question_data.rank)
        expect_element_prompt_to_be_displayed(question, question_data.prompt)
      end
    end

    xscenario 'I can do a multi type activity' do
      pending 'This is an intermittent failure, because sometimes cannot click the save button'
      question_1_choice = nil
      question_2_choice = nil
      question_4_answer = ''
      question_5_answer = ''

      multiple_choice_activity_data = activity_data.sub_activity(1)
      open_ended_activity_data = activity_data.sub_activity(2)

      visit section_activity_path(section.id, activity)

      for_preview_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_multiple_choice_question_contents_to_be_displayed(multiple_choice_activity_data)
        expect_open_ended_question_contents_to_be_displayed(open_ended_activity_data)
        expect(@page_object.attempts.remaining).to eq(3)

        from_multiple_choice_question(1) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_editable
        end

        from_multiple_choice_question(2) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_editable
        end

        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:blank)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_editable
        end

        from_open_ended_question(4) do |question|
          expect(question).to be_marked(:blank)
          expect(question.answer.text).to eq('')
        end

        from_open_ended_question(5) do |question|
          expect(question).to be_marked(:blank)
          expect(question.answer.text).to eq('')
        end

        from_open_ended_question(6) do |question|
          expect(question).to be_marked(:blank)
          expect(question.answer.text).to eq('')
        end

        from_open_ended_question(4) do |question|
          expect(question).to be_marked(:blank)
          expect(question.answer.text).to eq('')
        end

        # Answer correctly question 1, incorrectly questions 2 and don't answer question 3
        question_1_choice = multiple_choice_activity_data.question(1).correct_choice
        question_2_choice = multiple_choice_activity_data.question(2).incorrect_choices.first

        from_multiple_choice_question(1).select_choice(question_1_choice)
        from_multiple_choice_question(2).select_choice(question_2_choice)

        question_4_answer = 'some random answer for question 4'
        question_5_answer = 'some random answer for question 5'

        from_open_ended_question(4).choose_answer(question_4_answer)
        from_open_ended_question(5).choose_answer(question_5_answer)

        click_button_expect_alert(:save, answers_saved_no_submitted_msg)
        expect_flash_message(:notice, 'Your changes have been saved.')
      end

      # Reload the page
      visit section_activity_path(section.id, activity)
      for_decide_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_multiple_choice_question_contents_to_be_displayed(multiple_choice_activity_data)
        expect_open_ended_question_contents_to_be_displayed(open_ended_activity_data)
        expect(@page_object.attempts.remaining).to eq(3)

        # Every question should be marked as changed
        # and choices that were previously chosen and saved are already selected
        from_multiple_choice_question(1) do |question|
          expect(question).to be_marked(:changed)
          expect(question.choices)
            .to all_be_marked(:changed)
            .and all_be_editable
          expect(question.choice(question_1_choice)).to be_selected
        end

        from_multiple_choice_question(2) do |question|
          expect(question).to be_marked(:changed)
          expect(question.choices)
            .to all_be_marked(:changed)
            .and all_be_editable
          expect(question.choice(question_2_choice)).to be_selected
        end

        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:changed)
          expect(question.choices)
            .to all_be_marked(:changed)
            .and all_be_editable
            .and all_be_unselected
        end

        from_open_ended_question(4) do |question|
          expect(question).to be_marked(:changed)
          expect(question.answer.text).to eq(question_4_answer)
        end

        from_open_ended_question(5) do |question|
          expect(question).to be_marked(:changed)
          expect(question.answer.text).to eq(question_5_answer)
        end

        from_open_ended_question(6) do |question|
          expect(question).to be_marked(:changed)
          expect(question.answer.text).to eq('')
        end

        from_open_ended_question(7) do |question|
          expect(question).to be_marked(:changed)
          expect(question.answer.text).to eq('')
        end

        click_button_expect_alert(:submit, three_questions_not_answered_msg)
      end

      for_submit_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_multiple_choice_question_contents_to_be_displayed(multiple_choice_activity_data)
        expect_open_ended_question_contents_to_be_displayed(open_ended_activity_data)
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
            .to all_be_marked(:blank)
            .and all_be_uneditable
        end

        from_open_ended_question(4) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_4_answer)
        end

        from_open_ended_question(5) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_5_answer)
        end

        from_open_ended_question(6) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('')
        end

        from_open_ended_question(7) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('')
        end

        @page_object.button(:retry).click
      end

      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_multiple_choice_question_contents_to_be_displayed(multiple_choice_activity_data)
        expect_open_ended_question_contents_to_be_displayed(open_ended_activity_data)
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
            .to all_be_marked(:blank)
            .and all_be_editable
            .and all_be_unselected
        end

        from_open_ended_question(4) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_4_answer)
        end

        from_open_ended_question(5) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_5_answer)
        end

        from_open_ended_question(6) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('')
        end

        from_open_ended_question(7) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('')
        end

        # Change question 4 answer
        question_4_answer = 'A different answer for question 4'
        from_open_ended_question(4).choose_answer(question_4_answer)

        # and save without submitting
        click_button_expect_alert(:save, answers_saved_no_submitted_msg)
        expect_flash_message(:notice, 'Your changes have been saved.')
      end

      # Reload the page
      visit section_activity_path(section.id, activity)
      for_retry_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_multiple_choice_question_contents_to_be_displayed(multiple_choice_activity_data)
        expect_open_ended_question_contents_to_be_displayed(open_ended_activity_data)
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
            .and all_be_unselected
        end

        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_editable
            .and all_be_unselected
        end

        from_open_ended_question(4) do |question|
          expect(question).to be_marked(:changed)
          expect(question.answer.text).to eq(question_4_answer)
        end

        from_open_ended_question(5) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_5_answer)
        end

        from_open_ended_question(6) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('')
        end

        from_open_ended_question(7) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('')
        end

        # Save without making any changes should trigger a popup
        click_button_expect_alert(:save, no_changes_to_save_msg)

        # Submit the activity
        click_button_expect_alert(:submit, four_questions_not_answered_msg)
      end

      for_submit_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_multiple_choice_question_contents_to_be_displayed(multiple_choice_activity_data)
        expect_open_ended_question_contents_to_be_displayed(open_ended_activity_data)
        expect(@page_object.attempts.remaining).to eq(1)

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
            .to all_be_marked(:blank)
            .and all_be_uneditable
        end

        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank)
            .and all_be_uneditable
        end

        from_open_ended_question(4) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_4_answer)
        end

        from_open_ended_question(5) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_5_answer)
        end

        from_open_ended_question(6) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('')
        end

        from_open_ended_question(7) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('')
        end

        click_button_expect_alert(:accept, 'You have chosen to accept your grade of 4.3%.')
      end

      for_accept_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect_multiple_choice_question_contents_to_be_displayed(multiple_choice_activity_data)
        expect_open_ended_question_contents_to_be_displayed(open_ended_activity_data)

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
            .to all_be_marked(:blank).except(
              multiple_choice_activity_data.question(2).correct_choice => :correction
            ).and all_be_uneditable
        end

        from_multiple_choice_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question.choices)
            .to all_be_marked(:blank).except(
              multiple_choice_activity_data.question(3).correct_choice => :correction
            ).and all_be_uneditable
        end

        from_open_ended_question(4) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_4_answer)
        end

        from_open_ended_question(5) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq(question_5_answer)
        end

        from_open_ended_question(6) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('(No student response)')
        end

        from_open_ended_question(7) do |question|
          expect(question).to be_marked(:pending)
          expect(question.answer.text).to eq('(No student response)')
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
