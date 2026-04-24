require 'page_objects/page_object'
require 'page_objects/button_object'

class InstructorDashboardPageObject < PageObject
  def course_contextual_menu(course)
    wrapper = page.all('.test-course-navigation-wrapper').detect do |w|
      w.find('.test-course-name')['data-course-name'] == course
    end
    InstructorDashboardCourseContextualMenuPageElement.new(wrapper)
  end

  def visit_course_contextual_menu(course, menu_entry)
    wrapper = course_contextual_menu(course)
    wrapper.open_contextual_menu
    case menu_entry
    when 'Edit Course'
      wrapper.edit_course
    when 'Add section'
      wrapper.add_section
    when 'Delete Course'
      wrapper.delete_course
    else
      raise ArgumentError, "invalid action '#{menu_entry}'"
    end
  end

  class InstructorDashboardCourseContextualMenuPageElement
    attr_accessor :wrapper

    def initialize(wrapper)
      self.wrapper = wrapper
    end

    def open_contextual_menu
      wrapper.find('.test-course-gear-icon').click
    end

    def close_contextual_menu
      wrapper.find('.test-course-gear-icon').click
    end

    def edit_course
      wrapper.click_link('Edit Course')
    end

    def add_section
      wrapper.click_link('Add section')
    end

    def delete_course
      wrapper.find('input[value="Delete Course"]').click
    end
  end

  def course_contextual_menu_entry(course, menu_entry)
    wrapper = page.all('.test-course-navigation-wrapper').detect do |w|
      w.has_selector?(".test-course-name[data-course-name='#{course}']")
    end
    wrapper.find('.test-course-gear .test-gear-option', text: menu_entry)
  end

  def button(id)
    element = case id
              # There are two add course link in the view.
              when :add_course then page.first('.test-course-add-link')
              else raise ArgumentError, "invalid button '#{id}'"
              end
    ButtonObject.new(element)
  end
end
