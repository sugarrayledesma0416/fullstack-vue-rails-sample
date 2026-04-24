require 'support/feature_spec_scrollable'

module RspecJsCommonHelpers
  include FeatureSpecScrollable

  def log_in_as(user)
    page.set_rack_session(cas_user: user.username)
    session = page.get_rack_session
    create(:persistent_session, session_id: session['session_id'], user_id: user.id)
  end

  def dump_the_page(file_name = nil)
    file_name ||= 'blah.html'
    File.open("public/#{file_name}", 'w:UTF-8') { |file| file.write(page.body) }
  end

  def take_screenshot
    @screenshot_count ||= 0
    screenshot_dir = Rails.root.join('public', 'tmp')
    FileUtils.makedirs(screenshot_dir)

    screenshot_file = "#{@screenshot_count}.png"
    page.save_screenshot(File.join(screenshot_dir, screenshot_file))
    @screenshot_count += 1

    puts "saved screenshot viewable at http://localhost/tmp/#{screenshot_file}"
  end

  def fill_in_froala(text)
    element = page.find('[contenteditable=true]')
    page.execute_script(
      %(
        const elm = arguments[0];
        elm.innerHTML = '#{text}';
        const inputEvent = document.createEvent('Events');
        inputEvent.initEvent('input', true, false);
        elm.dispatchEvent(inputEvent);
        const blurEvent = document.createEvent('Events');
        blurEvent.initEvent('blur', true, false);
        elm.dispatchEvent(blurEvent);
      ),
      element
    )
  end

  def fill_in_ckeditor(instance_id, text)
    # Ensure we don't attempt to set data for a CKEDITOR instance that
    # hasn't yet been instantiated.
    editor_instance = "CKEDITOR.instances['#{instance_id}']"
    Waiter.new.wait(2) do
      result = page.evaluate_script("typeof #{editor_instance}")
      result != 'undefined'
    end

    # Sometimes the setData call fails silently, possibly due to timing
    # issues where the CKEDITOR instance has been instantiated but is not
    # yet ready to accept data. Re-attempt in that case.
    Waiter.new.wait do
      page.execute_script("#{editor_instance}.setData('#{text}');")
      result = page.evaluate_script("#{editor_instance}.getData();")
      result.include?(text)
    end
  end

  # Textangular creates 2 html elements: a div and a input hidden
  # field with the name we are passing in, that's why [1] is
  # used, to grab the latter.
  def fill_in_textangular(name, text)
    page.execute_script("document.getElementsByName('#{name}')[1].value = '#{text}';")
  end

  # Execute a block with `element` passed as argument to the block
  # This avoid using temporary variables without well defined scope
  # It allows to structure the code like:
  # with_element(get_some_question) do |question|
  #   expect(question.prompt).to eq('blah')
  #   expect(question).to be_marked(:correct)
  #   etc...
  # end
  def with_element(element)
    yield element
  end

  # These methods should be used when normal capybara check/uncheck
  # methods fail because the form element has the .c-checkbox
  # class which hides the real form element behind a prettier styled version.
  # The :use_input_id version should be used if there is no label tag, or
  # if the label tag isn't sufficient for activating the element.
  def vhl_check(label_or_id, opts = {})
    if opts[:use_input_id]
      element = page.find("input##{label_or_id}")
      element.click unless element.checked?
    else
      element = page.find_field(label_or_id)
      page.find('label', text: label_or_id, match: :prefer_exact).click unless element.checked?
    end
  end

  def vhl_uncheck(label_or_id, opts = {})
    if opts[:use_input_id]
      element = page.find("input##{label_or_id}")
      element.click if element.checked?
    else
      element = page.find_field(label_or_id)
      page.find('label', text: label_or_id).click if element.checked?
    end
  end

  def vhl_toggle_check(label_or_id, value, opts = {})
    if value
      vhl_check(label_or_id, opts)
    else
      vhl_uncheck(label_or_id, opts)
    end
  end

  # This method should be used when normal capybara choose method fails
  # because the form element has the .c-radio class which hides the real form
  # element behind a prettier styled version.
  # If the label text for the radio button isn't predictable, or if there
  # is more than one radio button with the same label text, instead of the
  # label text for the label_finder argument, specify the content of the
  # "for" attribute of the label tag.
  # _opts is provided for compatiblity with existing choose method, to
  # make it easier for us to revert back to the native Capybara method if
  # we upgrade capybara to a version that's smart enough to figure out the
  # target better than it can now.
  def vhl_choose(label_finder, _opts = {})
    if page.has_selector?('label', text: label_finder)
      page.find('label', text: label_finder).click
    else
      page.find("label[for='#{label_finder}']").click
    end
  end
end
