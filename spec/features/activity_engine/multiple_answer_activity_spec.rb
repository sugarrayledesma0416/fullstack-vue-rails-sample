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
    create(
      :course,
      owner: instructor,
      program: program,
      allows_help_requests: true,
      allows_review_requests: true
    )
  end

  let(:fake_submissions) { {} }
  let(:answers_saved_no_submitted_msg) do
    'Your answers will be SAVED. They will NOT be submitted for a grade.'
  end
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity) { create_multiple_answer_activity(program) }
  let(:one_question_not_answered_msg) { '1 question is unanswered.' }

  let(:activity_data) do
    ActivityTest::ActivityData::MultipleAnswer.new(activity, [])
  end

  xcontext 'As a student' do
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
      question = from_multiple_answer_question(question_data.rank)
      expect_element_prompt_to_be_displayed(question, question_data.prompt)
    end

    def expect_choices_to_be_displayed(question_data)
      question = from_multiple_answer_question(question_data.rank)
      question_data.choices.each do |choice_data|
        choice = question.choice(choice_data.number)
        expect_element_prompt_to_be_displayed(choice, choice_data.prompt)
      end
    end

    scenario 'I can do a multiple answer activity' do
      visit section_activity_path(section.id, activity)
      question_1_choices = nil
      question_2_choices = nil
      question_3_choices = nil
      question_4_choices = nil
      question_5_choices = nil
      question_6_choices = nil

      for_preview_page(activity_data) do
        # Question 1: Choose distractor, leave correct answer unchecked
        question_1_choices = [activity_data.question(1).incorrect_choices.first]
        # Question 2: Choose both distractor and correct answer
        question_2_choices = activity_data.question(2).all_choices
        # Question 3: Leave both distractor and correct answer unchecked
        question_3_choices = []
        # Question 4: Choose correct answer, leave distractor unchecked
        question_4_choices = activity_data.question(4).correct_choices
        # Question 5: Choose first correct answer, leave second unchecked
        question_5_choices = [activity_data.question(5).correct_choices.first]
        # Question 6: Choose correct answer, leave all distractors unchecked
        question_6_choices = [activity_data.question(6).correct_choices.first]

        from_multiple_answer_question(1).select_choices(question_1_choices)
        from_multiple_answer_question(2).select_choices(question_2_choices)
        from_multiple_answer_question(3).select_choices(question_3_choices)
        from_multiple_answer_question(4).select_choices(question_4_choices)
        from_multiple_answer_question(5).select_choices(question_5_choices)
        from_multiple_answer_question(6).select_choices(question_6_choices)

        # Save without submitting
        click_button_expect_alert(:save, answers_saved_no_submitted_msg)

        # Reload the page
        visit section_activity_path(section.id, activity)
        for_decide_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_question_contents_to_be_displayed
          expect(@page_object.attempts.remaining).to eq(3)

          from_multiple_answer_question(1) do |question|
            expect(question).to have_checked_only(question_1_choices)
            expect(question.choices)
              .to all_be_editable
          end
          from_multiple_answer_question(2) do |question|
            expect(question).to have_checked_only(question_2_choices)
            expect(question.choices)
              .to all_be_editable
          end
          from_multiple_answer_question(3) do |question|
            expect(question).to have_checked_only(question_3_choices)
            expect(question.choices)
              .to all_be_editable
          end
          from_multiple_answer_question(4) do |question|
            expect(question).to have_checked_only(question_4_choices)
            expect(question.choices)
              .to all_be_editable
          end
          from_multiple_answer_question(5) do |question|
            expect(question).to have_checked_only(question_5_choices)
            expect(question.choices)
              .to all_be_editable
          end
          from_multiple_answer_question(6) do |question|
            expect(question).to have_checked_only(question_6_choices)
            expect(question.choices)
              .to all_be_editable
          end
        end

        click_button_expect_alert(:submit, one_question_not_answered_msg)
      end

      for_submit_page(activity_data) do
        from_multiple_answer_question(1) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_1_choices)
        end
        from_multiple_answer_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_2_choices)
        end
        from_multiple_answer_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_3_choices)
        end
        from_multiple_answer_question(4) do |question|
          expect(question).to be_marked(:correct)
          expect(question).to have_checked_only(question_4_choices)
        end
        from_multiple_answer_question(5) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_5_choices)
        end
        from_multiple_answer_question(6) do |question|
          expect(question).to be_marked(:correct)
          expect(question).to have_checked_only(question_6_choices)
        end

        @page_object.button(:retry).click
      end

      for_retry_page(activity_data) do
        from_multiple_answer_question(1) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_1_choices)
          # expect(question.choices).to all_be_uneditable
        end
        from_multiple_answer_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_2_choices)
        end
        from_multiple_answer_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_3_choices)
        end
        from_multiple_answer_question(4) do |question|
          expect(question).to be_marked(:correct)
          expect(question).to have_checked_only(question_4_choices)
        end
        from_multiple_answer_question(5) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_5_choices)
        end
        from_multiple_answer_question(6) do |question|
          expect(question).to be_marked(:correct)
          expect(question).to have_checked_only(question_6_choices)
        end

        # TODO: Change some of the incorrect answers. Correct one question
        #       marked incorrect, and choose a different incorrect choice
        #       for another question.
        #       Save the activity, then reload the page. Validate that
        #       the saved answers are restored. See
        #       multiple_choice_activity_spec.rb lines 307 through 352.

        click_button_expect_alert(:submit, one_question_not_answered_msg)
      end

      for_submit_page(activity_data) do
        from_multiple_answer_question(1) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_1_choices)
        end
        from_multiple_answer_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_2_choices)
        end
        from_multiple_answer_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_3_choices)
        end
        from_multiple_answer_question(4) do |question|
          expect(question).to be_marked(:correct)
          expect(question).to have_checked_only(question_4_choices)
        end
        from_multiple_answer_question(5) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_5_choices)
        end
        from_multiple_answer_question(6) do |question|
          expect(question).to be_marked(:correct)
          expect(question).to have_checked_only(question_6_choices)
        end

        click_button_expect_alert(:accept, 'You have chosen to accept your grade of 33.3%.')
      end

      for_accept_page(activity_data) do
        from_multiple_answer_question(1) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_1_choices)
        end
        from_multiple_answer_question(2) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_2_choices)
        end
        from_multiple_answer_question(3) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_3_choices)
        end
        from_multiple_answer_question(4) do |question|
          expect(question).to be_marked(:correct)
          expect(question).to have_checked_only(question_4_choices)
        end
        from_multiple_answer_question(5) do |question|
          expect(question).to be_marked(:incorrect)
          expect(question).to have_checked_only(question_5_choices)
        end
        from_multiple_answer_question(6) do |question|
          expect(question).to be_marked(:correct)
          expect(question).to have_checked_only(question_6_choices)
        end
      end
    end
  end

  scenario 'As an instructor, I can view the answer key' do
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

    for_submit_page(activity_data) do
      (1..6).each do |question_number|
        from_multiple_answer_question(question_number) do |question|
          question_data = activity_data.question(question_number)
          expect(question).to have_checked_only(question_data.correct_choices)
        end
      end
    end
  end
end
