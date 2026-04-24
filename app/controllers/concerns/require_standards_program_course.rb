module RequireStandardsProgramCourse
  extend ActiveSupport::Concern
  private def require_standards_program_and_course
    current_course = current_section.course
    return if current_course.standard_sets.present? && current_program.supports_standards?

    if current_course.standard_sets.blank?
      flash[:error] = 'This course does not support standards'
    end

    unless current_program.supports_standards?
      flash[:error] = 'This program does not support standards'
    end

    redirect_to gradebook_engine.course_section_analytics_overview_path
  end
end

