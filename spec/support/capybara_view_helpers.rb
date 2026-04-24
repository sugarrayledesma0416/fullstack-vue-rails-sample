#  encoding: utf-8

module CapybaraViewHelpers
  # The following methods are helpers to find capybara elements in a page.
  # To have better error messages when an element is not found, one must
  # pass a target object that responds to .to_s
  # Example of rspec output:
  # 1) Multiple choice activity as a student I can do a multiple choice activity
  #    Failure/Error:
  #      raise ExpectationNotMet, "Unable to find #{target} " \
  #        "using selector '#{selector}'.\nCaused by: #{e.class}: #{e.message}"
  #
  #    ActivityTest::ExpectationNotMet:
  #      Unable to find multiple_choice_question(1) using selector '#activity_shell ol.answers li[value="1"]'.
  #      Caused by: Capybara::ElementNotFound: Unable to find css "#activity_shell ol.answers li[value=\"1\"]"

  # Find a capybara element on the page using the selector `selector` and raise
  # an error if the element is not found.
  def find_or_fail(selector, target, element: nil)
    element ||= page
    element.find(selector)
  rescue StandardError => e
    raise ExpectationNotMet, "Unable to find #{target} " \
      "using selector '#{selector}'.\nCaused by: #{e.class}: #{e.message}"
  end

  def element_find_or_fail(element, selector, target)
    find_or_fail(selector, target, element: element)
  end

  # Return the first capybara element on the page using the selector `selector`
  # and raise an error if no element is found
  def find_first_or_fail(selector, target, element: nil)
    element ||= page
    element.first(selector)
  rescue StandardError => e
    raise ExpectationNotMet, "Unable to find #{target} " \
      "using selector '#{selector}'.\nCaused by: #{e.class}: #{e.message}"
  end

  def element_find_first_or_fail(element, selector, target)
    find_first_or_fail(selector, target, element: element)
  end

  # Return the nth capybara element on the page using the selector `selector`
  # and raise an error if no such element is found
  def find_nth_or_fail(selector, number, target, element: nil)
    element ||= page
    elements = element.all(selector)
    if elements.size <= number
      raise ArgumentError, "Unable to find #{target} using selector '#{selector}'"
    end
    elements[number]
  end

  # Return the nth capybara element in `element` using the selector `selector`
  # and raise an error if no such element is found
  def element_find_nth_or_fail(element, selector, number, target)
    find_nth_or_fail(selector, number, target, element: element)
  end

  class ExpectationNotMet < StandardError; end

  def expect_flash_message(type, message)
    expect(page).to have_selector(".test-flash-#{type}", text: message, visible: true)
  end

  def expect_no_flash_message(type)
    expect(page).to have_no_selector(".test-flash-#{type}", visible: true)
  end

  def expect_url(expected_url)
    current_url = URI.parse(page.current_url).request_uri
    expect(current_url).to eq(expected_url)
  end

  RSpec::Matchers.define :not_exist do
    match(&:not_exist?)
  end
end
