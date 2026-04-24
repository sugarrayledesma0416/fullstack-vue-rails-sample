feature 'Diagnostic V2 summative activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  let(:course) do
    create(:course, owner: instructor, program: program)
  end

  let(:category) { create(:category, course: course, penalty_percent: 0, max_attempts: 1) }
  let(:activities) do
    {
      formative: create_formative_activity(program),
      summative: create_summative_activity(program)
    }
  end

  let(:fake_submissions) { {} }

  let(:all_questions_unanswered) do
    '50 questions are unanswered.'
  end

  before do
    activities.each_value do |act|
      create(
        :assignment,
        assignable: act,
        category: category,
        due_date: Date.yesterday,
        section: section
      )
    end
    initialize_fake_submissions_client
    give_user_access_to_program(student, program)
    give_user_access_to_program(instructor, program)
    create(:active_enrollment, section: section, user: student)
    log_in_as(student)
  end

  context 'with a student' do
    scenario 'I can see a study plan for formative and summative activities' do
      # submit the formative activity
      visit section_activity_path(section.id, activities[:formative])
      expect(page).to have_selector('.diagnostic_v2')
      for_preview_page({}) do
        click_button_expect_alert(:submit, all_questions_unanswered)
      end
      wait_for_ajax(3)
      expect(page).to have_selector('.test-study-plan-v2-formative')

      # submit the summative activity
      visit section_activity_path(section.id, activities[:summative])
      expect(page).to have_selector('.diagnostic_v2')
      for_preview_page({}) do
        click_button_expect_alert(:submit, all_questions_unanswered)
      end
      wait_for_ajax(3)

      # test that the study plan displays
      expect(page).to have_selector('.test-study-plan-v2-summative')
      expect(page).not_to have_selector('.test-toggled-activity', visible: true)
      expect(page).to have_selector('.test-donut-container')
      expect(page).to have_selector('.test-all-concepts-table')
      # test that analytics views do not leak through
      expect(page).not_to have_selector('.test-vocabulary-table')
      expect(page).not_to have_selector('.test-grammar-table')
      # test column headers
      within '.c-header-row' do
        expect(page).to have_selector('.test-concept-column')
        expect(page).to have_selector('.test-recapitulacion-de-vocabulario-column')
        expect(page).to have_selector('.test-prueba-de-practica-column')
        expect(page).to have_selector('.test-review-column')
        expect(page).to have_selector('.test-practice-column')
      end

      # test toggling between study plan and results
      page.find('.test-open-my-answers').click
      Waiter.new.wait { page.driver.browser.window_handles.size == 2 }
      page.driver.browser.switch_to.window(
        page.driver.browser.window_handles.last
      )
      expect(page).to have_current_path(
        section_activity_path(section.id, activities[:summative], show: 'my-answers')
      )
      expect(page).to have_selector('.c-activity-wrapper')
      expect(page).not_to have_selector('.study-plan-wrapper')

      page.driver.browser.close
      page.driver.browser.switch_to.window(
        page.driver.browser.window_handles.first
      )
      Waiter.new.wait { page.driver.browser.window_handles.size == 1 }
      toggled_activity = find('.test-toggled-activity')
      toggled_study_plan = find('.study-plan-wrapper')
      expect(toggled_activity).not_to be_visible
      expect(toggled_study_plan).to be_visible
    end
  end
end
