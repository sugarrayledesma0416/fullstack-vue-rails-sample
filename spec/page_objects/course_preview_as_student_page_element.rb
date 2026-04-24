class CoursePreviewAsStudentPageElement
  attr_accessor :container

  def initialize(container)
    self.container = container
  end

  def show
    if expander_button[:class]&.exclude?('is-expanded')
      expander_button.click
    end
  end

  def hide
    if expander_button[:class]&.include?('is-expanded')
      expander_button.click
    end
  end

  private def expander_button
    container.find('button.test-expander-button')
  end

  def caption
    container.find('.preview-table__caption', visible: true).text
  end

  def sections
    container.all('tr.test-current-section', visible: true).map do |element|
      SectionPageElement.new(element)
    end
  end

  def previous_sections
    container.all('tr.test-previous-sections', visible: true).map do |element|
      PreviousSectionPageElement.new(element)
    end
  end

  class SectionPageElement
    attr_accessor :container

    def initialize(container)
      self.container = container
    end

    def instructor
      container.find('.test-current-user').text
    end

    def course
      container.find('.test-preview-table-course-name').text
    end

    def section
      container.find('.test-preview-table-section-name').text
    end
  end

  class PreviousSectionPageElement
    attr_accessor :container

    def initialize(container)
      self.container = container
    end

    def instructor
      container.find('.test-preview-table-instructor-name').text
    end

    def course
      container.find('.test-preview-table-course-name').text
    end

    def section
      container.find('.test-preview-table-section-name').text
    end
  end
end
