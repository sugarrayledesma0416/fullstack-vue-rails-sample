class CourseWithSectionBuilder
  attr_reader :course, :course_options

  def initialize(course, course_options)
    @course = course
    @course_options = course_options
  end

  def build
    {
      id: course.id,
      name: course.name,
      weeks: CourseTimeCalculator.formatted_time(course)[:weeks],
      enterprise: course.is_enterprise,
      template: course.is_template,
      sections: fetch_sections
    }
  end

  private def fetch_sections
    @course.is_enterprise ? fetch_enterprise_section : fetch_regular_sections
  end

  private def fetch_enterprise_section
    enterprise_section = @course.enterprise_section
    return [] unless enterprise_section

    [section_build(enterprise_section)]
  end

  private def fetch_regular_sections
    @course_options.sections_for_course(course.id).map do |section|
      section_build(section)
    end
  end

  private def section_build(section)
    {
      id: section.id,
      class_days_count: section.class_days.split(',').count,
      name: section.name
    }
  end
end
