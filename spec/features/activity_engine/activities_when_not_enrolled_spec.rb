feature 'Completing activities when not enrolled in a course',
  js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include ActivityTest::Helpers
  include CapybaraViewHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:section) { Section.section_zero }
  let!(:media_items) do
    Array.new(4) do |i|
      id = i + 1
      create(:media_item_image, id: id, filename: "multiple_choice_prompt_#{id}.gif")
    end
  end
  let(:max_attempts) { 3 }
  let(:activity) do
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'dropdown.xml'),
      program,
      grading_method: 'auto',
      max_attempts: max_attempts
    )
  end
  let(:activity_data) do
    ActivityTest::ActivityData::DropDown.new(activity, media_items)
  end
  let(:fake_submissions) { {} }
  let(:answers_saved_no_submitted_msg) do
    'Your answers will be SAVED. They will NOT be submitted for a grade.'
  end
  let(:one_question_not_answered_msg) { '1 question is unanswered.' }
  let(:warning_modal_selector) { '.js-modal-not-enrolled-submission-warning' }

  def validate_warning_modal
    within(page.find(warning_modal_selector)) do
      expect(page).to have_selector(
        '.test-warning_message',
        text: 'Completed assignments cannot be transferred to a course.',
        visible: true
      )

      click_on('Confirm')
    end
  end

  def validate_no_warning_modal
    expect(page).to have_no_selector(warning_modal_selector)
  end

  context 'As a student not enrolled in a course,' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
    end

    scenario 'I see a message informing that my work will be lost once I ' \
             'enroll in a course' do
      purpose 'I do not see any warning message when I start an activity' do
        visit section_activity_path(section, activity)

        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          validate_no_warning_modal
        end
      end

      purpose 'I see a warning message when I save my work' do
        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          from_drop_down_question(1).drop_down_menu(1).select_option(
            activity_data.question(1).menu(1).correct_option.number
          )
          from_drop_down_question(2).drop_down_menu(1).select_option(
            activity_data.question(2).menu(1).incorrect_options.first.number
          )
          from_drop_down_question(3).drop_down_menu(1).select_option(
            activity_data.question(3).menu(1).incorrect_options.first.number
          )

          click_save_button_expect_message(answers_saved_no_submitted_msg)
        end

        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Your changes have been saved.')

          validate_warning_modal
        end
      end

      purpose 'I see a warning message when I reload my work' do
        visit section_activity_path(section, activity)

        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          validate_warning_modal
        end
      end

      purpose 'I see a warning message when I submit my work' do
        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          click_button_expect_alert(:submit, one_question_not_answered_msg)
        end

        for_submit_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          validate_warning_modal
        end
      end

      purpose 'I see a warning mesage when I retry my work' do
        for_submit_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          @page_object.button(:retry).click
        end

        for_retry_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          validate_warning_modal
        end
      end

      purpose 'I see a warning message when I change my work and submit' do
        for_retry_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          # Correct question 2, menu 1
          question_2_menu_1_option = activity_data.question(2).menu(1).correct_option
          from_drop_down_question(2).drop_down_menu(1).select_option(
            question_2_menu_1_option.number
          )

          # Submit the activity
          click_button_expect_alert(:submit, one_question_not_answered_msg)
        end

        for_submit_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_no_flash_message(:notice)

          validate_warning_modal
        end
      end

      purpose 'I see a warning message when I accept my grade' do
        for_submit_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          click_button_expect_alert(
            :accept, 'You have chosen to accept your grade of 50.0%.'
          )
        end

        for_accept_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Results finalized')

          validate_warning_modal
        end
      end

      purpose 'I do not see any warning message when I am in practice mode' do
        for_accept_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          @page_object.button(:practice).click
        end

        for_practice_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Practice mode. Answers will not be saved!')

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when viewing answers' do
        for_practice_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          click_button_expect_alert(
            :answers, '4 questions are unanswered.'
          )
        end

        for_accept_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Viewing answers')

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when I am in practice mode' do
        for_accept_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          @page_object.button(:practice).click
        end

        for_practice_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Practice mode. Answers will not be saved!')

          validate_no_warning_modal
        end
      end

      purpose 'I see a warning message when checking my answers' do
        for_practice_page(activity_data) do
          click_button_expect_alert(
            :check, '4 questions are unanswered.'
          )
        end

        for_practice_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Practice mode. Answers will not be saved!')

          validate_no_warning_modal
        end
      end
    end

    context 'when the activity has only one attempt,' do
      let(:max_attempts) { 1 }

      scenario 'I see a message informing that my work will be lost once I ' \
        'enroll in a course' do
        purpose 'I do not see any warning message when I start an activity' do
          visit section_activity_path(section, activity)

          for_preview_page(activity_data) do
            expect_activity_shell_structure_to_be_complete

            validate_no_warning_modal
          end
        end

        purpose 'I see a warning message when I submit my work' do
          for_preview_page(activity_data) do
            expect_activity_shell_structure_to_be_complete

            from_drop_down_question(1).drop_down_menu(1).select_option(
              activity_data.question(1).menu(1).correct_option.number
            )
            from_drop_down_question(2).drop_down_menu(1).select_option(
              activity_data.question(2).menu(1).incorrect_options.first.number
            )
            from_drop_down_question(2).drop_down_menu(2).select_option(
              activity_data.question(2).menu(2).incorrect_options.first.number
            )
            from_drop_down_question(3).drop_down_menu(1).select_option(
              activity_data.question(3).menu(1).incorrect_options.first.number
            )

            @page_object.button(:submit).click
          end

          for_accept_page(activity_data) do
            expect_activity_shell_structure_to_be_complete
            expect_flash_message(:notice, 'Activity complete.')

            validate_warning_modal
          end
        end
      end
    end
  end

  context 'As an instructor,' do
    before do
      initialize_fake_submissions_client
      initialize_program_access_client_calls_for_instructor(instructor, program)
      log_in_as(instructor)
    end

    scenario 'I do not see any message informing that my work will be lost ' \
             'once I enroll in a course' do
      purpose 'I do not see any warning message when I start an activity' do
        visit section_activity_path(section, activity)

        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when I save my work' do
        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          from_drop_down_question(1).drop_down_menu(1).select_option(
            activity_data.question(1).menu(1).correct_option.number
          )
          from_drop_down_question(2).drop_down_menu(1).select_option(
            activity_data.question(2).menu(1).incorrect_options.first.number
          )
          from_drop_down_question(3).drop_down_menu(1).select_option(
            activity_data.question(3).menu(1).incorrect_options.first.number
          )

          click_save_button_expect_message(answers_saved_no_submitted_msg)
        end

        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Your changes have been saved.')

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when I reload my work' do
        visit section_activity_path(section, activity)

        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when I submit my work' do
        for_preview_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          click_button_expect_alert(:submit, one_question_not_answered_msg)
        end

        for_submit_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning mesage when I retry my work' do
        for_submit_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          @page_object.button(:retry).click
        end

        for_retry_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when I change my work and submit' do
        for_retry_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          # Correct question 2, menu 1
          question_2_menu_1_option = activity_data.question(2).menu(1).correct_option
          from_drop_down_question(2).drop_down_menu(1).select_option(
            question_2_menu_1_option.number
          )

          # Submit the activity
          click_button_expect_alert(:submit, one_question_not_answered_msg)
        end

        for_submit_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_no_flash_message(:notice)

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when I accept my grade' do
        for_submit_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          click_button_expect_alert(
            :accept, 'You have chosen to accept your grade of 50.0%.'
          )
        end

        for_accept_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Results finalized')

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when I am in practice mode' do
        for_accept_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          @page_object.button(:practice).click
        end

        for_practice_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_no_flash_message(:notice)

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when viewing answers' do
        for_practice_page(activity_data) do
          click_button_expect_alert(
            :answers, '4 questions are unanswered.'
          )
        end

        for_accept_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Activity complete.')

          validate_no_warning_modal
        end
      end

      purpose 'I do not see any warning message when I am in practice mode' do
        for_accept_page(activity_data) do
          expect_activity_shell_structure_to_be_complete

          @page_object.button(:practice).click
        end

        for_practice_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_no_flash_message(:notice)

          validate_no_warning_modal
        end
      end

      purpose 'I see a warning message when checking my answers' do
        for_practice_page(activity_data) do
          click_button_expect_alert(
            :check, '4 questions are unanswered.'
          )
        end

        for_accept_page(activity_data) do
          expect_activity_shell_structure_to_be_complete
          expect_flash_message(:notice, 'Activity complete.')

          validate_no_warning_modal
        end
      end
    end
  end
end
