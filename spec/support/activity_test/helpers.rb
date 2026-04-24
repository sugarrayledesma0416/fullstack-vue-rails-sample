require 'support/activity_test/matchers'
require 'support/activity_test/mock_submissions'
require 'support/activity_test/page_objects'

module ActivityTest
  module Helpers
    include ActivityTest::MockSubmissions
    include ActivityTest::Matchers
    include ActivityTest::PageObjects

    def expect_element_prompt_to_be_displayed(element, expected_prompt)
      if expected_prompt.has_table?
        expect(element.table_prompts.map { |prompt| prompt.gsub(/\s|\n|\t/, '') })
          .to eq(expected_prompt.table.prompts.map { |prompt| prompt.gsub(/\s|\n|\t/, '') })
      else
        expected_prompt.text_elements.each do |prompt|
          expect(element.prompt_text).to include(prompt.text)
        end
      end
      expected_prompt.image_elements.each.with_index(1) do |prompt, i|
        expect(element.prompt_image(i)['src']).to end_with(prompt.image.filename)
      end
    end

    def expect_element_table_to_be_displayed(element)
      expect(element.prompt_text).to_not be_nil
    end

    # Show accent bar on footer iff activity is composition or contains composition(CK Editor).
    def accent_bar_on_footer_exist?(activity)
      return true if activity.activity_type == 'composition'
      return activity.sub_activities.any? { |act| act.activity_type == 'composition' } if activity.has_sub_activities?
      false # No composition in the activity
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
      # instructor notes
      expect(page).to have_selector('#instructor_notes_container')
      # vtext
      if activity_data.activity.page.present?
        expect(page).to have_selector(
          '#vtext_reference',
          text: activity_data.activity.page
        )
      end
      # buttons
      BasePageObject::BUTTON_SELECTORS.each do |id, selector|
        if @page_object.default_buttons.include?(id)
          expect(page).to have_selector(selector)
        else
          expect(page).to have_no_selector(selector)
        end
      end
    end

    # Add an instructor help request or an instructor review request
    # Params:
    # - item: Which item the help/review request should be atached to.
    # - comment: The help/review request comment.
    # - helpable: Array of page objects that can receive help/review request.
    # - non_helpable: Array of page objects that can't receive help/review request.
    # - help_request_element: clickable Capybara element used to add the help/review request.
    # - success_message: expected success message after adding the help/review request
    def validate_adding_instructor_request(item:, comment:, helpable:, non_helpable:,
                               help_request_element:, success_message:)
      # all items should not be helpable
      helpable.each do |item|
        expect(item).not_to be_helpable
      end
      non_helpable.each do |item|
        expect(item).not_to be_helpable
      end
      Waiter.new.wait do
        # Click on the element to ask for help/review
        help_request_element.click
        # and verify that the click event worked by waiting for the element to
        # be hidden.
        !help_request_element.visible?
      end
      # Now helpable items should be helpable
      helpable.each do |item|
        expect(item).to be_helpable
      end
      # Non helpable items should not be helpable
      non_helpable.each do |item|
        expect(item).not_to be_helpable
      end
      # And the specified item should be helpable
      expect(item).to be_helpable
      # Select an item
      item.select_as_helpable
      # Find modal box container
      modal = page.find('.test-modal-box')
      # Set comment
      modal.find('textarea#student_comment').set(comment)
      # Submit
      modal.find('.test-submit-help-request').click
      expect(page.find('.test-flash-banner--success')).to have_text(success_message)
    end

    def validate_adding_instructor_help_request(item:, comment:, helpable:, non_helpable:)
      help_request_element = @page_object.find_or_fail('.test-request-help', 'test-request-help')
      validate_adding_instructor_request(
        item: item,
        comment: comment,
        helpable: helpable,
        non_helpable: non_helpable,
        help_request_element: help_request_element,
        success_message: 'Help request successfully submitted!'
      )
    end

    def expect_help_request_to_be_displayed(item:, request_number:, comment:)
      item.show_help_requests
      expect(item.help_request(request_number).student_name).to eq('Me')
      expect(item.help_request(request_number).comment).to eq(comment)
      item.hide_help_requests
    end

    def remove_help_request(item:, request_number:)
      item.show_help_requests
      item.help_request(request_number).remove
      expect(page.find('.test-flash-banner--success')).to have_text('Help request successfully deleted!')
      item.hide_help_requests
    end

    def remove_review_request(item:, request_number:)
      item.show_help_requests
      item.review_request(request_number).remove
      expect(page.find('.test-flash-banner--success')).to have_text('Review request successfully deleted!')
      item.hide_help_requests
    end

    def validate_adding_instructor_review_request(item:, comment:, helpable:, non_helpable:)
      help_request_element = @page_object.find_or_fail('.test-request-review', 'test-request-review')
      validate_adding_instructor_request(
        item: item,
        comment: comment,
        helpable: helpable,
        non_helpable: non_helpable,
        help_request_element: help_request_element,
        success_message: 'Review request successfully submitted!'
      )
    end

    def expect_review_request_to_be_displayed(item:, request_number:, comment:)
      item.show_help_requests
      expect(item.review_request(request_number).student_name).to eq('Me')
      expect(item.review_request(request_number).comment).to eq(comment)
      item.hide_help_requests
    end

    # Validate that the specified items are helpable or not when asking for
    # instructor help request or review request.
    # Params:
    # - help_request_element: clickable Capybara element used to add the help/review request.
    # - helpable: Array of page objects that can receive help/review request.
    # - non_helpable: Array of page objects that can't receive help/review request.
    def validate_items_helpability(help_request_element:, helpable:, non_helpable:)
      # all items should not be helpable
      helpable.each do |item|
        expect(item).not_to be_helpable
      end
      non_helpable.each do |item|
        expect(item).not_to be_helpable
      end
      Waiter.new.wait do
        # Click on the element to ask for help/review
        help_request_element.click
        # and verify that the click event worked by waitin for the elemen to
        # be hidden.
        !help_request_element.visible?
      end
      # Now helpable items should be helpable
      helpable.each do |item|
        expect(item).to be_helpable
      end
      # Non helpable items should not be helpable
      non_helpable.each do |item|
        expect(item).not_to be_helpable
      end
    end

    def validate_add_instructor_help_request_items_helpability(helpable:, non_helpable:)
      help_request_element = @page_object.find_or_fail('.test-request-help', 'test-request-help')
      validate_items_helpability(
        help_request_element: @page_object.find_or_fail('.test-request-help', 'test-request-help'),
        helpable: helpable,
        non_helpable: non_helpable
      )
    end

    def validate_add_instructor_review_request_items_helpability(helpable:, non_helpable:)
      help_request_element = @page_object.find_or_fail('.test-request-review', 'test-request-review')
      validate_items_helpability(
        help_request_element: @page_object.find_or_fail('.test-request-review', 'test-request-review'),
        helpable: helpable,
        non_helpable: non_helpable
      )
    end

    def click_button_expect_alert(button_id, alert_msg)
      expect(
        accept_alert do
          @page_object.button(button_id).click
        end
      ).to start_with(alert_msg)
    end

    def click_save_button_expect_message(save_msg)
      @page_object.button(:save).click
      expect(@page_object).to have_selector('.test-save-modal-message', text: save_msg)
      @page_object.find('.test-ok-button').click
    end
  end
end
