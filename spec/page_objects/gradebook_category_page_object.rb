require 'page_objects/page_object'

class GradebookCategoryPageObject < PageObject
  def button(id)
    element = case id
              when :back then page.find('.test-category-back-button')
              when :next then page.find('.test-category-next-button')
              when :save then page.find('.test-category-save-button')
              when :done then page.find('.test-edit-category-done', text: 'Done')
              when :cancel then page.find('.test-category-cancel-link', text: 'cancel')
              else raise ArgumentError, "invalid button '#{id}'"
              end
    ButtonObject.new(element)
  end

  def name=(name)
    page.find(name_selector).set(name)
  end

  def name
    page.find(name_selector).value
  end

  def name_selector
    'input[name="name"]'
  end

  def weighting_percent=(value)
    page.find(weighting_percent_selector).set(value)
  end

  def weighting_percent
    page.find(weighting_percent_selector).value
  end

  def weighting_percent_selector
    'input[name="weighting_percent"]'
  end

  def credit_only=(enabled)
    page.find(credit_only_selector(enabled)).set(true)
  end

  def credit_only
    page.find(credit_only_selector(true)).checked?
  end

  def drop_low_scores=(value)
    page.select value, from: 'drop_lowest_scores'
  end

  def drop_low_scores
    page.all('#drop_lowest_scores option').detect(&:selected?).value
  end

  def max_attempts=(value)
    page.select value, from: 'max_attempts'
  end

  def max_attempts
    page.all('.test-max-attempts option').detect(&:selected?).value
  end

  def take_accent_mark_into_account=(value)
    vhl_toggle_check(take_accent_mark_into_account_label, value)
  end

  def take_accent_mark_into_account
    page.find_field(take_accent_mark_into_account_label).checked?
  end

  def take_capitalization_into_account=(value)
    vhl_toggle_check(take_capitalization_into_account_label, value)
  end

  def take_capitalization_into_account
    page.find_field(take_capitalization_into_account_label).checked?
  end

  def take_punctuation_into_account=(value)
    vhl_toggle_check(take_punctuation_into_account_label, value)
  end

  def take_punctuation_into_account
    page.find_field(take_punctuation_into_account_label).checked?
  end

  def enhanced_feedback=(value)
    page.find(enhanced_feedback_selector(value)).set(true)
  end

  def enhanced_feedback
    page.find(enhanced_feedback_selector(true)).checked?
  end

  def enhanced_feedback_selector(value)
    value ? 'input[name="enhanced_feedback_enabled"]' : 'input[name="enhanced_feedback_disabled"]'
  end

  def confirm_enhanced_feedback_disable
    page.find(enhanced_feedback_disable_confirm_selector).click
  end

  def enhanced_feedback_disable_confirm_selector
    '.test-enhanced-feedback-modal .test-confirm-btn'
  end

  def accept_late_work=(value)
    page.find(accept_late_work_selector(value)).set(true)
  end

  def accept_late_work
    page.find(accept_late_work_selector(true)).checked?
  end

  def late_work_penalty=(penalty)
    page.find(late_work_penalty_selector(penalty)).set(true)
  end

  def late_work_penalty
    %i[none per_day flat].detect do |penalty|
      page.find(late_work_penalty_selector(penalty)).checked?
    end
  end

  def late_work_penalty_percent_selector
    'input[name="penalty_percent"]'
  end

  def late_work_penalty_percent=(value)
    page.find(late_work_penalty_percent_selector).set(value)
  end

  def late_work_penalty_percent
    page.find(late_work_penalty_percent_selector).value
  end

  def select_tab(tab)
    text = case tab
           when :grading then 'Grading'
           when :lateness then 'Lateness'
           else raise ArgumentError, "invalid tab '#{tab}'"
           end
    page.find('.test-tab-list a', text: text).click
  end

  def has_enhanced_feedback_disable_warning?
    page.has_selector?(
      '.test-feedback-disable-warning',
      text: 'This will make it harder for students'\
        ' to see why their responses are incorrect.'
    )
  end

  def has_error_message_visible?(msg)
    page.has_selector?('div', text: error_message(msg), visible: true)
  end

  def has_error_message_hidden?(msg)
    page.has_no_selector?('div', text: error_message(msg), visible: true)
  end

  def error_message(id)
    case id
    when :late_work_penalty then 'A valid number is required.'
    when :name_already_in_use then 'This category name is already in use'
    when :weight_required then 'Category weight is required'
    when :invalid_weight_range then 'Category weight must be between 0 and 100'
    else raise ArgumentError, "invalid error message id '#{id}'"
    end
  end

  private def set_check_state(selector, value)
    elm = page.find(selector)
    if value
      page.check(elm['id'], allow_label_click: true)
    else
      page.uncheck(elm['id'], allow_label_click: true)
    end
  end
end
