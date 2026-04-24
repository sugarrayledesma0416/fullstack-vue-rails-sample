require 'page_objects/gradebook_category_page_object'

class AddGradebookCategoryPageObject < GradebookCategoryPageObject
  def credit_only_selector(value)
    value ? 'input[name="new_credit_only"]' : 'input[name="new_for_a_grade"]'
  end

  def take_accent_mark_into_account_label
    'Accent marks will be taken into account.'
  end

  def take_capitalization_into_account_label
    'Capitalization will be taken into account.'
  end

  def take_punctuation_into_account_label
    'Punctuation will be taken into account.'
  end

  def accept_late_work_selector(value)
    if value
      'input[name="new_accept_late_work"]'
    else
      'input[name="new_do_not_accept_late_work"]'
    end
  end

  def late_work_penalty_selector(penalty)
    case penalty
    when :none then 'input[name="new_late_work_penalty_none"]'
    when :per_day then 'input[name="new_late_work_penalty_day"]'
    when :flat then 'input[name="new_late_work_penalty_flat"]'
    else raise ArgumentError, "invalid late work penalty '#{penalty}'"
    end
  end

  def save
    page.click_button('Save')
  end
end
