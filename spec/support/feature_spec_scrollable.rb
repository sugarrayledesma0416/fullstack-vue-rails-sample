module FeatureSpecScrollable
  # Useful when you get errors like the following because an element is not
  # within the viewport.
  # Element <input class="red-button" id="submit_button" name="commit"
  # type="submit" value="Done"> is not clickable at point (1250, 1166).

  def scroll_to(element)
    if %i(chrome headless_chrome).include?(Capybara.javascript_driver)
      # Scroll the window to have the element in the middle of the viewport.
      # This avoid the case where the element is below a flash message and
      # then not clickable.
      # Works with chrome:
      script = <<-JS
        y = arguments[0].getBoundingClientRect().top + pageYOffset - screen.height / 2;
        window.scrollTo(0, Math.max(y, 0));
      JS
      Capybara.current_session.driver.browser.execute_script(script, element.native)
    else
      # Works with poltergeist.
      page.execute_script("#{element.native}.scrollIntoView(true);")
    end
  end
end
