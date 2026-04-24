require 'page_objects/button_object'
require 'page_objects/page_object'

class SummaryPageObject < PageObject
  def start_date
    Date.parse(page.find('.test-summary-start-date').text)
  end

  def end_date
    Date.parse(page.find('.test-summary-end-date').text)
  end

  def first_unit
    page.find('.test-summary-first-unit-id').text
  end

  def last_unit
    page.find('.test-summary-last-unit-id').text
  end

  def has_no_standard_sets?
    page.has_no_selector?('.test-summary-standard-sets')
  end

  def standard_sets
    page.all('.test-summary-standard-set-name').map(&:text)
  end

  def category(index)
    SummaryCategoryPageObject.new(page.all('.test-category')[index])
  end

  def button(id)
    element = case id
              when :cancel
                page.find('.test-cancel-btn')
              when :back
                page.find('.test-back-btn', text: 'Previous')
              when :save
                page.find('.test-save-course', text: 'Save')
              when :save_changes
                page.find('.test-save-changes', text: 'Save changes')
              when :generate_pdf
                page.find('.test-generate-pdf', text: 'Generate PDF')
              else
                raise ArgumentError, "invalid button '#{id}'"
              end
    ButtonObject.new(element)
  end
end
