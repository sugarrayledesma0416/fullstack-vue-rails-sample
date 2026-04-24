# TODO: This spec uses code comments instead of `purpose` and `step` blocks for
#       documentation. It should be refactored to meet expected standards.
# TODO: Eliminate duplication in this feature spec by either (a) combining
#       sync settings tests with manual syncing tests or (b) bypassing the
#       sync settings updates for the manual syncing tests by setting the
#       context link attributes directly. Alternatively, move the sync
#       behavior tests to a separate feature or integration tests.
feature 'Lti Manual Sync', chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  def stub_line_item_api_calls(context_link)
    # TODO: This is problematic because it uses the same line_item_id and
    #       line_item_response for all sync levels and lines, which normally have
    #       unique resourceIds and, therefore, unique line item IDs and
    #       responses.
    line_item_id = "#{context_link.line_items_url}/123"
    line_item_response = {
      id: line_item_id,
      resourceId: 'cumulative',
      scoreMaximum: 100
    }

    stub_line_item_get_requests(context_link)
    stub_line_item_post_requests(context_link, line_item_response, line_item_id)
    stub_line_item_put_requests(line_item_id)
  end

  def stub_line_item_get_requests(context_link)
    resource_ids = ['cumulative', "activity_#{activity.id}", "lesson_#{lesson.id}"]
    resource_ids.each do |resource_id|
      stub_request(:get, context_link.line_items_url).with(
        query: { resource_id: resource_id }
      ).and_return(body: [].to_json, status: 200)
    end

    stub_request(:get, "#{context_link.line_items_url}/123/results")
      .and_return(body: [].to_json, status: 200)

    # check for existing line items
    stub_request(:get, context_link.line_items_url)
      .to_return(body: [].to_json, status: 200)
  end

  def stub_line_item_put_requests(line_item_id)
    stub_request(:put, line_item_id).to_return(
      body: {}.to_json,
      headers: { 'Content-Type' => line_item_content_type },
      status: 200
    )
  end

  def stub_line_item_post_requests(context_link, line_item_response, line_item_id)
    stub_request(:post, context_link.line_items_url).and_return(
      body: { id: 'valid id' }.to_json,
      status: 200
    )

    stub_request(:post, "#{line_item_id}/scores").to_return(
      body: [].to_json,
      headers: { 'Content-Type' => line_item_content_type },
      status: 200
    )

    stub_request(:post, context_link.line_items_url).to_return(
      body: line_item_response.to_json,
      headers: { 'Content-Type' => line_item_content_type },
      status: 200
    )
  end

  def student_score_body(points_earned)
    {
      activityProgress: 'Completed',
      gradingProgress: 'FullyGraded',
      # The timestamp is the LTI score version time. Strictly increasing with
      # each transmission since we don't track whether we've previously sent
      # a score.
      timestamp: Time.now.utc.iso8601(3),
      userId: student_1_lms_id,
      scoreGiven: points_earned,
      scoreMaximum: 100.0
    }.to_json
  end

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:category) { create(:category, course: course, name: 'Homework', penalty_percent: 0) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:student_1) { create(:student) }
  let(:student_1_lms_id) { SecureRandom.hex(10) }
  let(:activity) { create_multiple_choice_activity(program) }
  let(:platform) { create(:lti_platform) }
  let(:schoology_platform) { create(:lti_platform, lms_type: 'Schoology') }
  # The score submission for individual activities includes the submitted_at time from the
  # gradebook database in UTC with no microseconds.
  let(:submitted_at) { 2.days.ago.utc.change(usec: 0) }

  let(:concept) { activity.concept }
  let(:lesson) { activity.lesson }
  let(:strand) { activity.strand }

  let(:lms_sync_nav_label) { 'LMS Sync' }
  let(:lms_sync_edit_label) { 'Edit Settings' }
  let(:sync_now_label) { 'Sync Now' }
  let(:column_warning) { 'On the next sync, removal of unused columns in the LMS will be attempted.' \
                         ' Note this operation is not supported by all LMSs.' }
  let(:sync_init_message) { 'LMS grade sync initiated.' }

  let(:schoology_warning_cancel_button_id) { 'schoology_cancel_button' }
  let(:schoology_warning_next_button_id) { 'schoology_next_button' }
  let(:schoology_warning_confirmation_label) { 'I understand and have set up a default category in Schoology.' }

  let(:line_item_content_type) { GradebookEngine::Lti::LineItem::LINE_ITEM_TYPE }

  let(:ags_access_token_string) { 'eyJ0eXAiOiJKV1QiLC' }

  let(:ags_scopes) do
    GradebookEngine::Lti::Constants::SCOPES.values_at(
      :ags_line_item, :ags_result, :ags_score
    ).join(' ')
  end

  let(:ags_token_response) do
    {
      access_token: ags_access_token_string,
      expires_in: 3600,
      scope: ags_scopes,
      token_type: 'Bearer'
    }.to_json
  end

  let(:line_item_headers) do
    {
      'Authorization' => "Bearer #{ags_access_token_string}",
      'Content-Type' => line_item_content_type,
    }
  end

  let!(:assignment) do
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: Date.yesterday,
      section: section
    )
  end

  before do
    # oauth request
    stub_request(:post, platform.oauth2_url).to_return(
      body: ags_token_response, status: 200
    )

    create(:enrollment, user: student_1, section: section)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'As an instructor, I can enable grade syncing to an LMS' do
    student_2 = create(:student)
    create(:enrollment, user: student_2, section: section)
    create(
      :lti_user_link,
      lti_platform: platform,
      user: student_1,
      platform_user_id: student_1_lms_id
    )

    purpose 'I do not see a link to set up LMS grade syncing if ' \
            'the current section is not linked to an LMS context' do
      # Go to the gradebook page showing activity-level scores.
      visit activities_for_lesson_url

      expect(page).to have_no_link(lms_sync_nav_label)
    end

    purpose 'When the current section is linked to an LMS context, I see ' \
            'a link to set up LMS grade syncing' do
      context_link = create(
        :lti_context_link,
        lti_platform: platform,
        section: section
      )

      stub_line_item_api_calls(context_link)

      visit activities_for_lesson_url

      expect(page).to have_link(lms_sync_nav_label)
    end

    purpose 'Before enabling syncing I do not see alerts about students ' \
            'who are missing user links' do
      expect(page).to have_no_selector(
        ".test-missing_user_link_student_#{student_2.id}"
      )
    end

    purpose 'I can enable LMS grade syncing' do
      click_link(lms_sync_nav_label)

      wait_for_lms_fetch

      expect(page).to have_selector('.js-lti-sync-status', text: 'Disabled')
      expect(page).to have_selector('.js-lti-sync-level',
                                    text: 'Aggregated Grade For: All VHL Work')

      # manual sync button is not visible
      expect(page).not_to have_button(sync_now_label, visible: :visible)
      click_link(lms_sync_edit_label)

      expect(page).to have_unchecked_field(:sync_enabled_true)
      expect(page).to have_checked_field(:sync_enabled_false)

      # Column options are disabled until syncing is enabled
      expect(page).to have_field(:sync_level_Aggregated, disabled: true)
      expect(page).to have_field(:sync_level_Activity, disabled: true)
      expect(page).to have_field(:sync_level, disabled: true)

      # The default value should be Cumulative
      expect(page).to have_checked_field(:sync_level_Aggregated, disabled: true)
      expect(page).to have_select(:sync_level, selected: 'All VHL Work', disabled: true)

      purpose 'Confirm that activity-level options are not available' do
        expect(page).to have_no_field(:"category_ids_#{category.id}")
        expect(page).to have_no_field(:skip_unsubmitted_work)
      end

      vhl_check('Enabled', allow_label_click: true)

      # Column options are now enabled
      expect(page).to have_field(:sync_level_Aggregated, disabled: false)
      expect(page).to have_field(:sync_level_Activity, disabled: false)
      expect(page).to have_field(:sync_level, disabled: false)

      vhl_check('Aggregated grade for', allow_label_click: true)
      expect(page).to have_select(:sync_level, selected: 'All VHL Work', disabled: false)

      click_button('Save')

      wait_for_lms_fetch

      expect_flash_message(
        :notice,
        "LMS Sync has been Enabled. Level set to Cumulative. #{sync_init_message}"
      )

      # manual sync button is visible
      click_link(lms_sync_nav_label)

      expect(page).to have_button(sync_now_label)

      gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
        section_id: section.id
      )

      expect(gb_context_link).to have_attributes(
        sync_enabled: true,
        sync_level: 'Cumulative'
      )
    end

    purpose 'After enabling syncing I see alerts about students ' \
            'who are missing user links' do
      visit activities_for_lesson_url
      expect(page).to have_selector(
        ".test-missing_user_link_student_#{student_2.id}"
      )
    end

    purpose 'I can change the sync level' do
      click_link(lms_sync_nav_label)

      wait_for_lms_fetch

      click_link(lms_sync_edit_label)

      expect(page).to have_checked_field(:sync_level_Aggregated)
      expect(page).to have_select(:sync_level, selected: 'All VHL Work')
      expect(page).to have_unchecked_field(:sync_level_Activity)

      expect(page).not_to have_text(column_warning)

      within('.js-lms-sync-modal') do
        select 'Each Lesson', from: 'sync_level'
      end
      expect(page).to have_text(column_warning)

      click_button('Save')

      wait_for_lms_fetch

      expect(page).not_to have_selector('.test-modal-content', visible: :visible)

      expect_flash_message(
        :notice,
        "LMS Sync Level set to Lesson. #{sync_init_message}"
      )

      gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
        section_id: section.id
      )
      expect(gb_context_link).to have_attributes(
        sync_enabled: true,
        sync_level: 'Lesson'
      )
    end

    purpose 'I can disable LMS grade syncing' do
      click_link(lms_sync_nav_label)
      click_link(lms_sync_edit_label)

      expect(page).to have_checked_field(:sync_enabled_true)
      expect(page).to have_unchecked_field(:sync_enabled_false)

      vhl_check('Disabled', allow_label_click: true)

      # Column options are disabled until syncing is enabled
      expect(page).to have_field(:sync_level_Aggregated, disabled: true)
      expect(page).to have_field(:sync_level_Activity, disabled: true)
      expect(page).to have_field(:sync_level, disabled: true)

      click_button('Save')

      wait_for_lms_fetch

      expect_flash_message(:notice, 'LMS Sync has been Disabled')
      expect(page).not_to have_selector('.test-modal-content', visible: :visible)

      gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
        section_id: section.id
      )
      expect(gb_context_link).not_to be_sync_enabled
    end
  end

  # NOTE: The activity-level options here are relevant to Premium Roster service type too.
  scenario 'As an instructor associated with an LTI Platform with Simple Rostering' \
           'I can enable grade syncing to an LMS but only at Activity level' do
    platform.update!(service_type: 'Simple Roster')
    create(
      :lti_user_link,
      lti_platform: platform,
      user: student_1,
      platform_user_id: student_1_lms_id
    )
    context_link = create(
      :lti_context_link,
      lti_platform: platform,
      section: section
    )

    purpose 'When the current section is linked to an LMS context, I see ' \
            'a link to set up LMS grade syncing' do
      stub_line_item_api_calls(context_link)

      visit activities_for_lesson_url

      expect(page).to have_link(lms_sync_nav_label)
    end

    purpose 'I can enable LMS grade syncing but only for individual activity grades' do
      click_link(lms_sync_nav_label)

      wait_for_lms_fetch

      expect(page).to have_selector('.js-lti-sync-status', text: 'Disabled')

      # manual sync button is not visible
      expect(page).to have_no_button(sync_now_label, visible: :visible)
      click_link(lms_sync_edit_label)

      expect(page).to have_unchecked_field(:sync_enabled_true)
      expect(page).to have_checked_field(:sync_enabled_false)

      # Column options are disabled until syncing is enabled
      expect(page).to have_no_field(:sync_level_Aggregated, disabled: true)
      expect(page).to have_field(:sync_level_Activity, disabled: true)
      expect(page).to have_field(:sync_level, disabled: true)
      expect(page).to have_no_field(:"category_ids_#{category.id}")
      expect(page).to have_no_field(:skip_unsubmitted_work)

      # The default value should be Individual grades for Activities
      expect(page).to have_checked_field(:sync_level_Activity, disabled: true)

      vhl_check('Enabled', allow_label_click: true)

      # Column options are now enabled
      expect(page).to have_no_field(:sync_level_Aggregated)
      expect(page).to have_checked_field(:sync_level_Activity, disabled: false)
      expect(page).to have_field(:sync_level, disabled: false)
      expect(page).to have_unchecked_field("category_ids_#{category.id}")
      expect(page).to have_unchecked_field(:skip_unsubmitted_work, disabled: false)
      vhl_check('Individual grades for selected categories', allow_label_click: true)

      # Select activity-level options: categories and handling of unsubmitted work.
      vhl_check(category.name, allow_label_click: true)
      vhl_check('Skip unsubmitted work.', allow_label_click: true)

      click_button('Save')

      wait_for_lms_fetch

      expect_flash_message(
        :notice,
        'LMS Sync has been Enabled. Level set to include activities in ' \
        "Categories: #{category.name}. Skipping unsubmitted work. #{sync_init_message}"
      )
      gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
        section_id: section.id
      )

      expect(gb_context_link).to have_attributes(
        sync_enabled: true,
        sync_level: 'Activity',
        category_ids: [category.id.to_s],
        skip_unsubmitted_work: true
      )
    end
  end

  scenario 'As an instructor, I see the UI populated when fetching a context link' do
    category_2 = create(
      :category,
      course: course,
      name: 'Quiz',
      weighting_percent: 40
    )
    category_3 = create(
      :category,
      course: course,
      name: 'Exams',
      weighting_percent: 40
    )
    create(:lti_context_link, lti_platform: platform, section: section)

    visit activities_for_lesson_url

    purpose 'The UI is updated when the context link sync is enabled' do
      gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
        section_id: section.id
      )
      gb_context_link.update!(
        sync_enabled: true,
        sync_level: 'Lesson'
      )

      purpose 'The modal has been populated from the context link' do
        click_link(lms_sync_nav_label)
        wait_for_lms_fetch

        expect(page).to have_selector('.js-lti-sync-status', text: 'Enabled')
        expect(page).to have_selector(
          '.js-lti-sync-level',
          text: 'Aggregated Grade For: Each Lesson'
        )

        # manual sync button is visible
        expect(page).to have_button(sync_now_label, visible: :visible)
      end

      purpose 'The edit modal has been populated from the context link' do
        click_link(lms_sync_edit_label)

        expect(page).to have_checked_field(:sync_enabled_true)
        expect(page).to have_unchecked_field(:sync_enabled_false)

        # close the modal
        click_on('Cancel')
        find('.js-lms-sync-modal .test-modal-close').click
      end
    end

    purpose 'The UI is updated when the context link sync is disabled' do
      gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
        section_id: section.id
      )
      gb_context_link.update!(
        sync_enabled: false,
        sync_level: 'Week'
      )

      purpose 'The modal has been populated from the context link' do
        click_link(lms_sync_nav_label)
        wait_for_lms_fetch

        expect(page).to have_selector('.js-lti-sync-status', text: 'Disabled')
        expect(page).to have_selector(
          '.js-lti-sync-level',
          text: 'Aggregated Grade For: Each Week'
        )

        # manual sync button is not visible
        expect(page).to have_no_button(sync_now_label, visible: :visible)
      end

      purpose 'The edit modal has been populated from the context link' do
        click_link(lms_sync_edit_label)

        expect(page).to have_unchecked_field(:sync_enabled_true)
        expect(page).to have_checked_field(:sync_enabled_false)

        # Column options are disabled
        expect(page).to have_field(:sync_level_Aggregated, disabled: true)
        expect(page).to have_field(:sync_level_Activity, disabled: true)
        expect(page).to have_field(:sync_level, disabled: true)

        # The correct sync level is selected
        expect(page).to have_checked_field(:sync_level_Aggregated, disabled: true)
        expect(page).to have_select(:sync_level, selected: 'Each Week', disabled: true)

        # close the modal
        click_on('Cancel')
        find('.js-lms-sync-modal .test-modal-close').click
      end
    end

    purpose 'The UI is updated when the context link sync level is set to activity' do
      gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
        section_id: section.id
      )
      gb_context_link.update!(
        category_ids: [category_2.id.to_s, category_3.id.to_s],
        sync_enabled: true,
        sync_level: 'Activity'
      )

      purpose 'The modal has been populated from the context link' do
        click_link(lms_sync_nav_label)
        wait_for_lms_fetch

        expect(page).to have_selector('.js-lti-sync-status', text: 'Enabled')

        expect(page).to have_checked_field(:sync_level_Activity)
        # TODO: Match the new line character. For now, bypass with RegExp.
        expect(page).to have_selector(
          '.js-lti-sync-level',
          text: Regexp.new(
            'Activities in Categories: ' \
            "#{Regexp.escape(category_2.name)}, #{Regexp.escape(category_3.name)}" \
            '.*Includes unsubmitted work'
          )
        )

        # manual sync button is visible
        expect(page).to have_button(sync_now_label, visible: :visible)
      end

      purpose 'The edit modal has been populated from the context link' do
        click_link(lms_sync_edit_label)

        expect(page).to have_checked_field(:sync_enabled_true)
        expect(page).to have_unchecked_field(:sync_enabled_false)

        # Column options are enabled
        expect(page).to have_field(:sync_level_Aggregated, disabled: false)
        expect(page).to have_field(:sync_level_Activity, disabled: false)
        expect(page).to have_field(:sync_level, disabled: false)

        # The correct sync level is selected
        expect(page).to have_checked_field(:sync_level_Activity)
        expect(page).to have_unchecked_field("category_ids_#{category.id}")
        expect(page).to have_checked_field("category_ids_#{category_2.id}")
        expect(page).to have_checked_field("category_ids_#{category_3.id}")
        expect(page).to have_unchecked_field(:skip_unsubmitted_work, disabled: false)

        # close the modal
        click_on('Cancel')
        find('.js-lms-sync-modal .test-modal-close').click
      end
    end
  end

  scenario 'As an instructor associated with a Schoology platform, I can enable grade syncing' do
    student_3 = create(:student)
    create(:enrollment, user: student_3, section: section)
    create(
      :lti_user_link,
      lti_platform: schoology_platform,
      user: student_1,
      platform_user_id: student_1_lms_id
    )

    purpose 'When the current section is linked to an LMS context, I see ' \
            'a link to set up LMS grade syncing' do
      context_link = create(
        :lti_context_link,
        lti_platform: schoology_platform,
        platform_type: 'Schoology',
        section: section
      )

      stub_line_item_api_calls(context_link)

      visit activities_for_lesson_url

      expect(page).to have_link(lms_sync_nav_label)
    end

    purpose 'I see a warning when I try to enable LMS grade syncing' do
      click_link(lms_sync_nav_label)

      wait_for_lms_fetch

      expect(page).to have_selector('.js-lti-sync-status', text: 'Disabled')
      expect(page).to have_selector('.js-lti-sync-level',
                                    text: 'Aggregated Grade For: All VHL Work')

      # manual sync button is not visible
      expect(page).not_to have_button(sync_now_label, visible: :visible)
      click_link(lms_sync_edit_label)

      expect(page).to have_unchecked_field(:sync_enabled_true)
      expect(page).to have_checked_field(:sync_enabled_false)

      # Column options are disabled until syncing is enabled
      expect(page).to have_field(:sync_level_Aggregated, disabled: true)
      expect(page).to have_field(:sync_level_Activity, disabled: true)
      expect(page).to have_field(:sync_level, disabled: true)

      # The default value should be Cumulative
      expect(page).to have_checked_field(:sync_level_Aggregated, disabled: true)
      expect(page).to have_select(:sync_level, selected: 'All VHL Work', disabled: true)

      vhl_check('Enabled', allow_label_click: true)

      expect(page).to have_button(schoology_warning_cancel_button_id, disabled: false)
      expect(page).to have_button(schoology_warning_next_button_id, disabled: true)
      expect(page).to have_unchecked_field(:schoology_confirmation_checkbox, disabled: false)

      click_button('schoology_cancel_button')

      # After cancelling the Schoology warning, sync is disabled
      expect(page).to have_unchecked_field(:sync_enabled_true)
      expect(page).to have_checked_field(:sync_enabled_false)

      # Column options are still disabled
      expect(page).to have_field(:sync_level_Aggregated, disabled: true)
      expect(page).to have_field(:sync_level_Activity, disabled: true)
      expect(page).to have_field(:sync_level, disabled: true)

      vhl_check('Enabled', allow_label_click: true)

      # Acknowledge the Schoology warning by checking the checkbox
      vhl_check(schoology_warning_confirmation_label, allow_label_click: true)

      # With the Schoology warning acknowledged, I can now proceed
      expect(page).to have_button(schoology_warning_next_button_id, disabled: false)

      click_button(schoology_warning_next_button_id)

      # Column options are now enabled
      expect(page).to have_field(:sync_level_Aggregated, disabled: false)
      expect(page).to have_field(:sync_level_Activity, disabled: false)
      expect(page).to have_field(:sync_level, disabled: false)

      vhl_check('Aggregated grade for', allow_label_click: true)
      expect(page).to have_select(:sync_level, selected: 'All VHL Work', disabled: false)

      click_button('Save')

      wait_for_lms_fetch

      expect_flash_message(
        :notice,
        "LMS Sync has been Enabled. Level set to Cumulative. #{sync_init_message}"
      )

      # manual sync button is visible
      click_link(lms_sync_nav_label)

      expect(page).to have_button(sync_now_label)

      gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
        section_id: section.id
      )

      expect(gb_context_link).to have_attributes(
        sync_enabled: true,
        sync_level: 'Cumulative'
      )
    end
  end

  scenario 'As an instructor, I can manually sync all grades to an LMS' do
    student_2 = create(:student)
    create(:enrollment, user: student_2, section:)
    student_2_lms_id = SecureRandom.hex(10)

    Timecop.freeze do
      score_content_type = GradebookEngine::Lti::Constants::MIME_TYPES[:score]
      create_gradebook_engine_submission(
        pending: false,
        points_earned: activity.points_possible - 2,
        points_possible: activity.points_possible,
        student: student_1,
        submitted_at: submitted_at
      )
      context_link = create(
        :lti_context_link,
        lti_platform: platform,
        section: section
      )
      stub_line_item_api_calls(context_link)

      student_1_user_link = create(
        :lti_user_link,
        lti_platform: create(:lti_platform),
        user: student_1,
        platform_user_id: student_1_lms_id
      )
      student_2_user_link = create(
        :lti_user_link,
        lti_platform: create(:lti_platform),
        user: student_2,
        platform_user_id: student_2_lms_id
      )

      line_item_id = "#{context_link.line_items_url}/123"

      purpose 'I see a link to sync my grades to my LMS only if the ' \
              'current section LMS syncing is enabled' do
        # Go to the gradebook page showing activity-level scores.
        visit activities_for_lesson_url

        # open LMS sync settings
        click_link(lms_sync_nav_label)

        wait_for_lms_fetch

        # syncing is disabled, sync button is missing
        expect(page).to have_no_selector('.test-ags-sync-grades', visible: :visible)

        click_link(lms_sync_edit_label)

        expect(page).to have_unchecked_field(:sync_enabled_true, visible: :visible)

        vhl_check('Enabled', allow_label_click: true)

        click_button('Save')
        click_link(lms_sync_nav_label)
        # now we have a sync button
        expect(page).to have_selector('.test-ags-sync-grades')
      end

      # Sidekiq testing mode is initiated for this entire test.
      # To see the response from the form submission and prevent an extra sync,
      # testing mode needs to be disabled.
      Sidekiq::Testing.disable! do
        purpose 'I see that grade syncing has started' do
          click_button(sync_now_label)
          wait_for_lms_fetch
          expect_flash_message(:notice, 'LMS grade sync initiated.')
        end
      end

      purpose 'I can sync my grades' do
        student_1_user_link.update!(lti_platform_id: platform.id)

        click_link(lms_sync_nav_label)

        click_button(sync_now_label)

        wait_for_lms_fetch

        # check that the line item was posted
        # TODO: This should not be posted twice for a given sync.
        #       Nor should it be posted if the line item already exists from
        #       a previous sync. syncing should happen every time the "Save" and
        #       "Sync Now" buttons are clicked. This spec is not well-scoped to
        #       test this because `feature` is the only `context` block.
        expect(
          a_request(:post, context_link.line_items_url).with(
            body: {
              label: 'VHL Cumulative',
              resourceId: 'cumulative',
              scoreMaximum: 100.0,
              tag: 'Grade',
              endDateTime: assignment.due_date_time.utc.strftime('%Y-%m-%dT%H:%M:%S%z')
            }.to_json,
            headers: line_item_headers
          )
        ).to have_been_made.twice

        # check that the score was posted
        expect(
          a_request(:post, "#{line_item_id}/scores").with(
            body: student_score_body(75.0),
            headers: {
              'Authorization' => "Bearer #{ags_access_token_string}",
              'Content-Type' => score_content_type
            }
          )
        ).to have_been_made
      end

      purpose 'I can sync grades by Category' do
        category.update!(name: 'Homework', weighting_percent: 60)
        category_2 = create(
          :category,
          course: course,
          name: 'Quiz',
          weighting_percent: 40
        )
        activity_2 = create_multiple_choice_activity(program)

        create(
          :assignment,
          assignable: activity_2,
          category: category_2,
          due_date: Date.yesterday,
          section: section
        )

        stub_request(:get, context_link.line_items_url).with(
          query: { resource_id: "category_#{category.id}" }
        ).and_return(body: [].to_json, status: 200)

        stub_request(:get, context_link.line_items_url).with(
          query: { resource_id: "category_#{category_2.id}" }
        ).and_return(body: [].to_json, status: 200)

        click_link(lms_sync_nav_label)

        wait_for_lms_fetch

        click_link(lms_sync_edit_label)

        expect(page).to have_checked_field(:sync_level_Aggregated)
        expect(page).to have_select(:sync_level, selected: 'All VHL Work')
        expect(page).to have_unchecked_field(:sync_level_Activity)

        within('.js-lms-sync-modal') do
          select 'Each Category', from: 'sync_level'
        end
        expect(page).to have_text(column_warning)

        click_button('Save')

        wait_for_lms_fetch

        expect(page).not_to have_selector('.test-modal-content', visible: :visible)

        expect_flash_message(
          :notice,
          "LMS Sync Level set to Category. #{sync_init_message}"
        )

        gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
          section_id: section.id
        )
        expect(gb_context_link).to have_attributes(
          sync_enabled: true,
          sync_level: 'Category'
        )

        click_link(lms_sync_nav_label)

        click_button(sync_now_label)

        expect(
          a_request(:post, context_link.line_items_url).with(
            body: {
              label: 'VHL Homework Category',
              resourceId: "category_#{category.id}",
              scoreMaximum: 100.0,
              tag: 'Grade',
              endDateTime: assignment.due_date_time.utc.strftime('%Y-%m-%dT%H:%M:%S%z')
            }.to_json,
            headers: line_item_headers
          )
        ).to have_been_made

        expect(
          a_request(:post, context_link.line_items_url).with(
            body: {
              label: 'VHL Quiz Category',
              resourceId: "category_#{category_2.id}",
              scoreMaximum: 100.0,
              tag: 'Grade',
              endDateTime: assignment.due_date_time.utc.strftime('%Y-%m-%dT%H:%M:%S%z')
            }.to_json,
            headers: line_item_headers
          )
        ).to have_been_made

        # TODO: This test is missing post score calls. See other TODO items for
        #       reasons why this may not have been included.
      end

      purpose 'I can sync grades by Activities in a Category' do

        click_link(lms_sync_nav_label)

        wait_for_lms_fetch

        click_link(lms_sync_edit_label)

        expect(page).to have_checked_field(:sync_level_Aggregated)
        expect(page).to have_select(:sync_level, selected: 'Each Category')
        expect(page).to have_unchecked_field(:sync_level_Activity)

        within('.js-lms-sync-modal') do
          vhl_check(
            'Individual grades for selected categories (one or more required)',
            allow_label_click: true
          )
          vhl_check(Course.last.categories.first.name, allow_label_click: true)
          vhl_check('Skip unsubmitted work.', allow_label_click: true)
        end
        expect(page).to have_text(column_warning)

        # When we click `Save`, a sync happens. (POST 1)
        click_button('Save')

        wait_for_lms_fetch

        expect(page).not_to have_selector('.test-modal-content', visible: :visible)

        expect_flash_message(
          :notice,
          "LMS Sync Level set to include activities in Categories: #{category.name}. " \
          'Skipping unsubmitted work. ' \
          "#{sync_init_message}"
        )

        gb_context_link = GradebookEngine::Lti::ContextLink.find_by(
          section_id: section.id
        )
        expect(gb_context_link).to have_attributes(
          category_ids: [category.id.to_s],
          skip_unsubmitted_work: true,
          sync_enabled: true,
          sync_level: 'Activity'
        )

        click_link(lms_sync_nav_label)

        expect(page).to have_checked_field(:sync_level_Activity)
        # Unable to match the new line character, bypass with RegExp.
        expect(page).to have_selector(
          '.js-lti-sync-level',
          text: Regexp.new(
            'Activities in Categories: ' \
            "#{Regexp.escape(category.name)}" \
            '.*Skips unsubmitted work'
          )
        )

        click_button(sync_now_label)

        assignment = Assignment.where(
          assignable_type: 'Activity',
          assignable_id: activity.id
        ).last
        due_date_time = assignment.due_date_time.utc.strftime('%FT%T%z')

        expect(
          a_request(:post, context_link.line_items_url).with(
            body: {
              label: "VHL #{activity.title}",
              resourceId: "activity_#{activity.id}",
              scoreMaximum: activity.points_possible.to_f,
              tag: 'Grade',
              endDateTime: due_date_time
            }.to_json,
            headers: line_item_headers
          )
        ).to have_been_made

        # TODO: This should not be posted three times for a given sync.
        #       However, this spec is not well-defined to test this because
        #       (a) `feature` is the only `context` block,
        #       (b) the line_item_id is not unique, and
        #       (c) the stubbing for the `results` request does not return
        #           realistic data based on previously stubbed requests.
        expect(
          a_request(:post, "#{line_item_id}/scores").with(
            body: student_score_body(75.0),
            headers: {
              'Authorization' => "Bearer #{ags_access_token_string}",
              'Content-Type' => score_content_type
            }
          )
        ).to have_been_made.times(3)

        purpose 'I do not sync grades for unsubmitted work' do
          expect(
            a_request(:post, "#{line_item_id}/scores").with { |req|
              JSON.parse(req.body)['userId'] == student_2_lms_id
            }
          ).not_to have_been_made
        end
      end
    end
  end
end
