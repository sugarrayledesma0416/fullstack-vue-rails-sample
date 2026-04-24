require 'page_objects/page_object'
require 'page_objects/button_object'

class ExpressCourseSetupPageObject < PageObject
  def course_name=(name)
    page.find(course_name_selector).set(name)
  end

  def course_name
    page.find(course_name_selector).value
  end

  def course_name_selector
    '.test-course-name-input'
  end

  def start_date=(date)
    page.find(start_date_selector).set(format_date(date))

    # Click any where to close the datepicker
    page.find(course_name_selector).click
  end

  def start_date
    Date.parse(page.find(start_date_selector).value)
  end

  def start_date_selector
    '.test-start-date'
  end

  def end_date=(date)
    page.find(end_date_selector).set(format_date(date))

    # Click any where to close the datepicker
    page.find(course_name_selector).click
  end

  def end_date
    Date.parse(page.find(end_date_selector).value)
  end

  def end_date_selector
    '.test-end-date'
  end

  private def format_date(date)
    date.is_a?(Date) ? date.strftime('%m/%d/%Y') : date
  end

  def number_of_sections=(number)
    page.select(number, from: number_of_sections_selector)
  end

  def number_of_sections
    page.find_field(number_of_sections_selector).value.to_i
  end

  private def number_of_sections_selector
    'section-dropdown'
  end

  def sections
    page.all('.test-section-name-input').map do |element|
      SectionPageElement.new(element)
    end
  end

  class SectionPageElement
    attr_accessor :element

    def initialize(element)
      self.element = element
    end

    def name=(value)
      element.set(value)
    end

    def name
      element.value
    end
  end

  def allow_student_enrollment_selector
    '.test-allow-students'
  end

  def co_instructor_form_selector
    '#hide_owner_name'
  end

  def has_error_message_visible?(msg)
    selector, text = error_message(msg)
    page.has_selector?(selector, text: text, visible: true)
  end

  def has_error_message_hidden?(msg)
    selector, text = error_message(msg)
    page.has_no_selector?(selector, text: text, visible: true)
  end

  def error_message(id)
    case id
    when :course_name_required then ['.test-course-name-validation-error', 'Course name is required.']
    when :course_name_length then ['.test-course-name-validation-error', 'Your course name cannot be longer than 75 characters.']
    when :section_name_length then ['.test-section-name-validation-error', 'Your section name cannot be longer than 75 characters.']
    when :invalid_date then ['span', 'Invalid date']
    when :end_date_before_start_date then ['.test-course-date-validation-error', 'Your end date cannot be before your start date.']
    else raise ArgumentError, "invalid error message id '#{id}'"
    end
  end

  def button(id)
    element = case id
              when :cancel
                page.find('.test-cancel-btn', text: 'CANCEL', visible: true)
              when :back
                page.find('.test-back-btn', text: 'PREVIOUS', visible: true)
              when :next
                page.find('.test-next-btn', text: 'NEXT', visible: true)
              else
                raise ArgumentError, "invalid button '#{id}'"
              end
    ButtonObject.new(element)
  end

  def preview_as_student
    CoursePreviewAsStudentPageElement.new(page.find('.test-vhl-expander'))
  end
end
