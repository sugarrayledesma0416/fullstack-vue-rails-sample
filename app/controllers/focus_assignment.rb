# extend your controller by adding:
# include FocusAssignment
# requires a program_id param
# then set a before_action corresponding to the the assignment variables
# you need populated

module FocusAssignment
  def self.included(controller)
    controller.helper_method :current_focus
  end

  def set_current_program
    @current_program = Program.find_by_id(params[:program_id])
  end
  protected :set_current_program

  def set_current_focus
    @current_focus = Focus.new(current_user, program, session[:focus])
  end
  protected :set_current_focus

  def program
    @program ||= current_program
  end
  protected :program

  def current_focus
    @current_focus
  end
  protected :current_focus

  def assign_course_sections_and_students_from_focus
    @course = current_focus.course
    @sections = current_focus.sections
    @students = current_focus.students
  end
  protected :assign_course_sections_and_students_from_focus

  private def get_closed_course_section_from_session
    return [] unless session.has_key?(:closed_course_section)

    if session[:closed_course_section].has_key?(:section_id) && session[:closed_course_section][:section_id]
      section = Section.find(session[:closed_course_section][:section_id])
      return [section.name, "Section,#{section.id}"] if section
    end
    if session[:closed_course_section].has_key?(:course_id) && session[:closed_course_section][:course_id]
      course = Course.find(session[:closed_course_section][:course_id])
      return [course.name, "Course,#{course.id}"] if course
    end
    []
  end

  # After a newly created course or section, set the focus to that course,
  # and optionally to a specific section.
  private def set_focus_after_creation(course, section: nil)
    session[:focus] = {} if session[:focus].nil?
    session[:stashed_focus] = session[:focus]
    session[:saved_focus] = session[:focus] = {
      course.program_id.to_s => {
        'course_id' => course.id,
        'section_id' => section&.id,
        'sort' => nil
      }
    }
    session[:activity_assignment] = nil
    program = Program.find(course.program_id)
    @current_focus = Focus.new(current_user, program, session[:focus])
  end
end
