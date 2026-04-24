xfeature 'Instructor Notes', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:note_selector) { '[data-content-type="instructor_activity_note"]' }
  let(:body_text_selector) { '[data-content-type="note_body_text"]' }
  let(:activity) { create_fill_in_the_blanks_activity_with_sidenotes(program) }

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    allow(SubmissionClient::Submission).to receive(:create).and_return(
      SubmissionClient::Submission.new('id' => 1)
    )

    allow(SubmissionClient::Submission).to receive(:find).and_return(
      [SubmissionClient::Submission.new('id' => 1, 'data' => {})]
    )
  end

  scenario 'As a learner I can view any activity with a VHL defined sidenote ' \
           'attached to some of it\'s content' do
    visit section_activity_path(0, activity)
    find('.sidebar_title_side').click
    expect(page).to have_selector('.open_sidebar')
  end

  def expect_find_sidebar
    expect(page).to have_selector('.sidebar_title_side')
  end

  describe 'sidebar notes rendering' do
    scenario 'As a learner I can view sidebar notes within submitted view' do
      visit section_activity_path(0, activity)

      # Preview
      expect_find_sidebar

      # Submit the activity
      submit_button = find('[data-button="submit"]')
      accept_alert do
        submit_button.click
      end

      # On decide view
      expect_find_sidebar

      # Choose to retry the activity
      click_button('_activity_retry')

      # On retry view
      expect_find_sidebar

      # Submit the activity
      submit_button = find('[data-button="submit"]')
      accept_alert do
        submit_button.click
      end

      # On decide view
      expect_find_sidebar

      # Accept the activity
      accept_alert do
        click_button('_activity_accept')
      end

      # On complete view
      expect_find_sidebar
    end

    scenario 'As an instructor I can view sidebar notes within answer key view' do
      visit answer_keys_section_activity_path(0, activity)
      expect_find_sidebar
    end
  end
end
