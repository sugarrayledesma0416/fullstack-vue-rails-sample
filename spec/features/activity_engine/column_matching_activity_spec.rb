feature 'Column Matching activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include CapybaraViewHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:one_question_not_answered_msg) { '1 question is unanswered.' }
  let(:fake_submissions) { {} }

  let(:course) do
    create(:course, owner: instructor, program: program)
  end

  # ID is needed here because is specified in fixture file.
  let!(:media_items) do
    Array.new(4) do |i|
      id = i + 1
      create(:media_item_image, id: id, filename: "multiple_choice_prompt_#{id}.gif")
    end
  end

  let(:activity) { create_column_matching_activity(program) }

  context 'with a student' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    scenario 'I can do a column matching activity' do
      visit section_activity_path(section.id, activity)
      pending('Mar 17, 20202: Column Matching will undergo UI changes next week.')

      # Get question 1 correct.
      find('.test-column-1-question_01').click
      find('.test-column-2-choice-1').click

      # Get questions 2 and 3 incorrect.
      find('.test-column-1-question_02').click
      find('.test-column-2-choice-3').click

      find('.test-column-1-question_03').click
      find('.test-column-2-choice-2').click

      # leave question 4 blank

      # Submit
      for_preview_page({}) do
        click_button_expect_alert(:submit, one_question_not_answered_msg)
      end

      expect(page).to have_selector('h1')
    end
  end
end
