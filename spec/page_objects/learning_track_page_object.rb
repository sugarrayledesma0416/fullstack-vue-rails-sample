require 'page_objects/page_object'
require 'page_objects/button_object'

class LearningTracksPageObject < PageObject
  def panels
    page.all('.panel--learning-tracks').map.with_index(1) do |container, index|
      case index
      when 1 then Step1PanelPageElement.new(container)
      when 2 then Step2PanelPageElement.new(container)
      when 3 then PanelPageElement.new(container)
      when 4 then Step4PanelPageElement.new(container)
      else
        raise "Expected to find 4 panels, found at least #{index}"
      end
    end
  end

  class PanelPageElement
    attr_accessor :container

    def initialize(container)
      self.container = container
    end

    def status
      classes = container[:class]
      if classes&.include?('is-active')
        :active
      elsif classes&.include?('is-finished')
        :finished
      elsif classes&.include?('is-upcoming')
        :upcoming
      else
        :disabled
      end
    end

    def header
      container.find('.panel__header').text
    end
  end

  class Step1PanelPageElement < PanelPageElement
    def course=(value)
      container.select(value, from: 'dropdown-step1-choose-course')
    end

    def section=(value)
      container.select(value, from: 'dropdown-step1-choose-section')
    end

    def learning_track_panel(name)
      # Find the correct learning track, based on its title
      panel_container = container.all('.predefined-tracks__track').detect do |track|
        track.find('.test-expander-button', visible: true).text.upcase == name.upcase
      end
      # Expand the learning track panel by clicking on the header
      panel_container.find('.test-expander-button').click
      # Wait for animation to complete
      panel_container.has_selector?('.expandable-body.expanded')
      # Return the learning track panel body
      panel_container.find('.test-expander-body')
    end

    def button(id)
      element = case id
                when :select
                  container.find('.test-select-existing-section', text: 'Select')
                when :change_course_template
                  container.find('a', text: 'Change course template')
                else
                  raise ArgumentError, "invalid button '#{id}'"
                end
      ButtonObject.new(element)
    end
  end

  class Step2PanelPageElement < PanelPageElement
    def start_lesson=(value)
      container.select(value, from: 'dropdown-step2-lesson-start')
    end

    def end_lesson=(value)
      container.select(value, from: 'dropdown-step2-lesson-end')
    end

    def show_options
      container.find('.test-toggle-lesson-options').click

      Waiter.new.wait do
        # Wait for the options to be visible and populated
        container.has_selector?('.test-lesson-options', visible: true) &&
          container.first('.test-strand-names label').text.present?
      end
    end

    def strands
      container.all('.test-strand-names .select-content__strand').map do |element|
        StrandPageElement.new(element)
      end
    end

    class StrandPageElement
      attr_accessor :container

      def initialize(container)
        self.container = container
      end

      def name
        container.text.strip
      end

      def checked?
        input.checked?
      end

      def check
        container.click unless checked?
      end

      def uncheck
        container.click if checked?
      end

      private def input
        container.find('input')
      end
    end

    def activity_types
      container.all('.test-activity-type').map do |element|
        ActivityTypePageElement.new(element)
      end
    end

    class ActivityTypePageElement
      attr_accessor :container

      def initialize(container)
        self.container = container
      end

      def name
        container.text.strip
      end

      def checked?
        input.checked?
      end

      def check
        container.click unless checked?
      end

      def uncheck
        container.click if checked?
      end

      private def input
        container.find('input')
      end
    end
  end

  class Step4PanelPageElement < PanelPageElement
    def due_dates
      container.all('.test-due-dates').map do |element|
        DueDatePageElement.new(element)
      end
    end

    def average_assignments_per_lesson
      container.find('.test-activities-per-lesson').text
    end

    def average_hours_of_work_per_due_date
      container.find('.test-assignments-per-lesson').text
    end

    class DueDatePageElement
      attr_accessor :container

      def initialize(container)
        self.container = container
      end

      def label
        label_element.text
      end

      def locked?
        container.has_selector?('.test-locked-due-date')
      end

      def unlocked?
        container.has_selector?('.test-unlocked-due-date')
      end

      def checked?
        input.checked?
      end

      def check
        label_element.click unless checked?
      end

      def uncheck
        label_element.click if checked?
      end

      private def label_element
        container.find('.checkbox-container')
      end

      private def input
        container.find('input')
      end
    end
  end

  def button(id)
    element = case id
              when :cancel
                page.find('.course-setup-controls a', text: 'cancel', visible: true)
              when :back
                page.find('.test-back-btn', text: 'Previous')
              when :save
                page.find('.test-save-course', text: 'Save')
              else
                raise ArgumentError, "invalid button '#{id}'"
              end
    ButtonObject.new(element)
  end
end
