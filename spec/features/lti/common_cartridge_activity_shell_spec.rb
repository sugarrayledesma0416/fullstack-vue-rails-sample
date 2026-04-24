feature 'Common cartridge activity shell', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include Capybara::Angular::DSL
  include ActivityTest::Helpers

  let(:instructor) { create(:cartridge_instructor_user_link).user }
  let(:student) { create(:cartridge_student_user_link).user }
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

  let(:activity) { create_fill_in_the_blanks_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::FillInTheBlanks.new(activity, media_items) }
  let(:student_path_to_activity) { cartridge_section_activity_path(section.id, activity) }
  let(:instructor_path_to_activity) { cartridge_section_activity_path('0', activity) }
  let(:fake_submissions) { {} }
  let(:answers_saved_no_submitted_msg) do
    'Your answers will be SAVED. They will NOT be submitted for a grade.'
  end
  let(:one_question_not_answered_msg) { '1 question is unanswered.' }
  let(:two_questions_not_answered_msg) { '2 questions are unanswered.' }
  let(:no_changes_to_save_msg) { 'No changes to save!' }
  let(:button_selectors) do
    {
      submit: '#_activity_submit',
      save: '#_activity_save',
      retry: '#_activity_retry',
      accept: '#_activity_accept',
      practice: '.activity_actions a[data-button="practice"]',
      answers: '.activity_actions input[value=Answers]',
      check: '.activity_actions input[value=Check]'
    }
  end

  def create_fill_in_the_blanks_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'fill_in_the_blanks.xml'),
      program,
      grading_method: 'auto'
    )
  end

  def expect_activity_shell_structure_to_be_complete
    view = @page_object.view
    page = @page_object.page
    activity_data = @page_object.activity_data

    unless activity_data.activity.santillana?
      # accent bar
      if %i[preview decide retry accept practice].include?(view) && accent_bar_on_footer_exist?(activity_data.activity)
        expect(@page_object.accent_bar).to exist
      end
      # attempts
      if activity_data.activity.submittable?
        expect(@page_object.attempts).to exist
      else
        expect(@page_object).to have_been_viewed
      end
      # activity title
      expect(@page_object.activity_title).to include(activity_data.title)
      # direction line
      expect(@page_object.direction_line.text).to include(activity_data.dl)
    end

    # buttons
    button_selectors.each do |id, selector|
      if @page_object.default_buttons.include?(id)
        expect(page).to have_selector(selector)
      else
        expect(page).to have_no_selector(selector)
      end
    end
  end

  context 'with a valid logged-in cartridge instructor' do
    it_behaves_like 'an instructor seeing a fill in the blanks activity' do
      scenario 'I can see view dashboard' do
        expect(page).to have_selector('.test-view-dashboard-link')
        expect(page).to have_link 'View dashboard', href: cartridge_instructor_section_grading_path(0, activity)
      end
    end
  end

  context 'with a valid logged-in cartridge student' do
    scenario "I don't see a header" do
      give_user_access_to_program(student, program)
      log_in_as(student)

      visit student_path_to_activity
      expect(page).to have_no_selector('.test-masthead-container')
    end

    scenario "I don't see the footer" do
      give_user_access_to_program(student, program)
      log_in_as(student)

      visit student_path_to_activity
      expect(page).to have_no_selector('.test-footer')
    end

    scenario "I don't see view dashboard"  do
      give_user_access_to_program(student, program)
      log_in_as(student)

      visit student_path_to_activity
      expect(page).to have_no_selector('.test-view-dashboard-link')
    end

    it_behaves_like 'a student doing the fill in the blanks activity'
  end
end
