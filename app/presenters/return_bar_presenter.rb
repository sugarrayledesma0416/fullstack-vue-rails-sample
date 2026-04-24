class ReturnBarPresenter
  include Enterprise::DisplayableCourses
  include Rails.application.routes.url_helpers

  attr_accessor :current_focus, :current_program, :current_user

  def initialize(current_user, current_focus, current_program)
    @current_user = current_user
    @current_focus = current_focus
    @current_program = current_program
    @current_year = Time.zone.today.year
  end

  def path_for_show_toc_template(course)
    institution_admin_show_toc_template_path(*program_course_section_args(course))
  end

  def find_assign_path(params, course)
    if params[:controller] == "institution_admin/toc_templates" && params[:action] == "show"
      path_for_show_toc_template(course)
    elsif params[:controller] == "institution_admin/assessment_templates" && params[:action] == "index"
      path_for_assessment_template(course)
    elsif params[:controller] == "institution_admin/assignment_templates" && params[:action] == "new"
      path_for_new_assignment_template(course)
    elsif params[:controller] == "institution_admin/assignment_templates" && params[:action] == "index"
      path_for_assignment_template(course)
    else
      path_for_assignment_wizard_template(course)
    end
  end

  def path_for_assessment_template(course)
    institution_admin_assessment_template_path(*program_course_section_args(course),
                                               display_lesson: display_lesson(course.enterprise_section),
                                               toc_location: toc_location(course.enterprise_section))
  end

  def path_for_new_assignment_template(course)
    institution_admin_new_assignment_template_path(*program_course_section_args(course))
  end

  def path_for_assignment_template(course)
    institution_admin_assignment_template_path(*program_course_section_args(course))
  end

  def path_for_assignment_wizard_template(course)
    institution_admin_assignment_wizard_template_path(*program_course_section_args(course))
  end

  def assigning_options(params)
    @assigning_options ||= begin
      course = Course.find(params[:course_id])
      dropdown_options = ["Activities", "Assessments", "Start Assigning", "Assignment Calendar", "Assignment Wizard"]

      available_options = Array.new
      available_options << ["Activities", path_for_show_toc_template(course)] unless params[:controller] == "institution_admin/toc_templates" && params[:action] == "show"
      available_options << ["Assessments", path_for_assessment_template(course)] unless params[:controller] == "institution_admin/assessment_templates" && params[:action] == "index"
      available_options << ["Start Assigning", path_for_new_assignment_template(course)] unless params[:controller] == "institution_admin/assignment_templates" && params[:action] == "new"
      available_options << ["Assignment Calendar", path_for_assignment_template(course)] unless params[:controller] == "institution_admin/assignment_templates" && params[:action] == "index"
      available_options << ["Assignment Wizard", path_for_assignment_wizard_template(course)] unless params[:controller] == "institution_admin/assignment_wizard_templates" && params[:action] == "index"

      { options: available_options, selected: (dropdown_options - available_options.collect { |x| x[0] }).first }
    end
  end

  def path_for_assignment_wizard_course(course)
    institution_admin_assignment_wizard_template_path(
      program_id: course.program.id,
      course_id: course.id,
      section_id: course.enterprise_section.id
    )
  end

  def current_course
    current_focus.course
  end

  def courses
    courses_by_school_current_or_later_year
      .joins(:sections)
      .open
      .by_program(current_program)
      .distinct
      .order(:name)
  end

  private def school
    current_course.school
  end

  private def program_course_section_args(course)
    [course.program.id, course.id, course.enterprise_section.id]
  end

  private def display_lesson(section)
    section.lessons_covered.first
  end

  private def toc_location(section)
    display_lesson(section).activities.first.toc_location
  end
end
