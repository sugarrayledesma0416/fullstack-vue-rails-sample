feature 'Allow custom question points possible values', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:fake_submissions) { {} }

  def create_fib_activity_with_4_points_possible(program)
    activity_content_path = File.join('spec', 'fixtures', 'xml', 'fib_with_4_points_possible.xml')
    activity = create_activity_with_unit_lesson_and_concept(program, max_attempts: 3)
    allow(Activity).to receive(:filepath_from_revision_id).and_return(activity_content_path)
    activity
  end

  def create_dd_activity_with_5_points_possible(program)
    activity_content_path = File.join('spec', 'fixtures', 'xml', 'dd_with_5_points_possible.xml')
    activity = create_activity_with_unit_lesson_and_concept(program, max_attempts: 3)
    allow(Activity).to receive(:filepath_from_revision_id).and_return(activity_content_path)
    activity
  end

  before do
    initialize_fake_submissions_client
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'I can submit a fill-in-the-blanks activity with custom points possible per question' do
    activity = create_fib_activity_with_4_points_possible(program)
    visit section_activity_path(0, activity)

    # Submit with one correct, one incorrect
    fill_in('question_01_wol_1', with: 'Answer1')
    fill_in('question_02_wol_1', with: 'WrongAnswer')
    find('[data-button="submit"]').click

    # Look for the points inside the status div
    expect(page).to have_selector('#status p', text: '4 of 8 pts. (50.0%)')

    # Click the accept button to verify question by question scores
    accept_alert do
      find('[data-button="accept"]').click
    end

    expect(page).to have_selector('li[value="1"] .item_score', text: '4 out of 4 points')
    expect(page).to have_selector('li[value="2"] .item_score', text: '0 out of 4 points')
  end

  scenario 'I can submit a drop-down activity with custom points possible per question' do
    activity = create_dd_activity_with_5_points_possible(program)
    visit section_activity_path(0, activity)

    # Submit with a mix of correct and incorrect
    click_on('question_01_1_dd_btn')
    within('.test-question_01_1-listbox') do
      find('li', text: 'answer_1_1').click
    end
    click_on('question_02_1_dd_btn')
    within('.test-question_02_1-listbox') do
      find('li', text: 'answer_2_1_2').click
    end
    click_on('question_02_2_dd_btn')
    within('.test-question_02_2-listbox') do
      find('li', text: 'answer_2_2_2').click
    end
    click_on('question_03_1_dd_btn')
    within('.test-question_03_1-listbox') do
      find('li', text: 'answer_3_2').click
    end

    find('[data-button="submit"]').click

    # Look for the points inside the status div
    expect(page).to have_selector('#status p', text: '15 of 20 pts. (75.0%)')

    # Click the accept button to verify question by question scores
    accept_alert do
      find('[data-button="accept"]').click
    end

    expect(page).to have_selector('li[value="1"] .item_score', text: '5 out of 5 points')
    expect(page).to have_selector('li[value="2"] .item_score', text: '5 out of 10 points')
    expect(page).to have_selector('li[value="3"] .item_score', text: '5 out of 5 points')
  end
end
