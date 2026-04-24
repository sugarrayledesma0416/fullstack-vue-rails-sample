require 'page_objects/gradebook_category_page_object'

class EditGradebookCategoryPageObject < GradebookCategoryPageObject
  def credit_only_selector(value)
    value ? 'input[name="credit_only"]' : 'input[name="for_a_grade"]'
  end

  def take_accent_mark_into_account_label
    'Accent marks count'
  end

  def take_capitalization_into_account_label
    'Capitalization counts'
  end

  def take_punctuation_into_account_label
    'Punctuation counts'
  end

  def accept_late_work_selector(value)
    value ? 'input[name="accept_late_work"]' : 'input[name="do_not_accept_late_work"]'
  end

  def late_work_penalty_selector(penalty)
    case penalty
    when :none then 'input[name="late_work_penalty_none"]'
    when :per_day then 'input[name="late_work_penalty_day"]'
    when :flat then 'input[name="late_work_penalty_flat"]'
    else raise ArgumentError, "invalid late work penalty '#{penalty}'"
    end
  end
end
