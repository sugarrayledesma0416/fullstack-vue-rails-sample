module WaitForNextPage
  # Waits for a page transition to complete by monitoring the body's data-rendered-at attribute
  # This is useful for ensuring that a new page has fully loaded after clicking a link or submitting a form
  def wait_for_next_page
    # Store the current page's rendered timestamp
    current_rendered_at = find('body')['data-rendered-at']

    # Execute the code that triggers the page transition
    yield

    # Wait until the body's data-rendered-at attribute changes, indicating a new page has loaded
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.has_no_css?("body[data-rendered-at='#{current_rendered_at}']")
    end
  end

  # Waits for a specific element to appear on the page
  # This is useful for ensuring dynamic content has loaded before interacting with it
  def wait_for_selector(selector, **kwargs)
    # Wait for the element to appear, with a longer timeout than default
    Timeout.timeout(Capybara.default_max_wait_time * 2) do
      loop until page.has_selector?(selector, **kwargs)
    end
  end
end
