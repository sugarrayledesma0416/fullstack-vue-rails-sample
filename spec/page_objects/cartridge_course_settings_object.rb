require 'page_objects/page_object'

class CartridgeCourseSettingsPageObject < PageObject
  def number_of_attempts_selector
    '.test-cartridge-number-attempts'
  end

  def accent_strictness_selector
    '.test-cartridge-strictness-accents'
  end

  def punctuation_strictness_selector
    '.test-cartridge-strictness-punctuation'
  end

  def capitalization_strictness_selector
    '.test-cartridge-strictness-capitalization'
  end

  def course_end_date_selector
    '.test-cartridge-course-end-date'
  end

  def number_of_attempts
    page.find(number_of_attempts_selector).value.to_i
  end

  def require_accent_strictness?
    page.find(accent_strictness_selector).checked?
  end

  def require_punctuation_strictness?
    page.find(punctuation_strictness_selector).checked?
  end

  def require_capitalization_strictness?
    page.find(capitalization_strictness_selector).checked?
  end

  def course_end_date
    Date.strptime(page.find(course_end_date_selector).value, datepicker_format)
  end

  def number_of_attempts=(option_value)
    select_option(number_of_attempts_selector, option_value)
  end

  def require_accent_strictness=(new_strictness)
    check_or_uncheck(accent_strictness_selector, new_strictness)
  end

  def require_punctuation_strictness=(new_strictness)
    check_or_uncheck(punctuation_strictness_selector, new_strictness)
  end

  def require_capitalization_strictness=(new_strictness)
    check_or_uncheck(capitalization_strictness_selector, new_strictness)
  end

  def course_end_date=(new_end_date)
    page.find(course_end_date_selector).set(new_end_date.strftime(datepicker_format))
  end

  def direction_line
    page.find('.test-cartridge-direction-line').text
  end

  def submit
    page.find('.js-main-action').click
  end

  def has_scrollable_modal?
    page.find('.c-modal > .c-modal__box.u-oflow-y-auto').visible?
  end

  private def select_option(css_selector, option_value)
    page.find(css_selector).find("option[value='#{option_value}']").select_option
  end

  private def datepicker_format
    '%m-%d-%Y'
  end

  private def check_or_uncheck(css_selector, value)
    element = page.find(css_selector)
    label = page.find("label[for=#{element[:id]}]")
    if value
      label.click unless element.checked?
    elsif element.checked?
      label.click
    end
  end
end
