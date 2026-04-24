class BestDefaultPath
  include Rails.application.routes.url_helpers

  attr_accessor :program, :section, :session, :user

  def self.best_default_path(user, program, section, session)
    self.new(user, program, section, session).best_default_path
  end

  # Program and section could both be nil.
  def initialize(user, program, section, session)
    self.program = program
    self.section = section
    self.session = session
    self.user = user
  end

  def best_default_path
    if user.student?
      best_default_student_path
    else
      best_default_instructor_path
    end
  end

  private def best_default_instructor_path
    target_program = program || user.programs.first

    if target_program
      instructor_dashboard_path(target_program.id)
    else
      ua_home_path
    end
  end

  private def best_default_student_path
    if section && user.active_section?(section)
      student_dashboard_path(section)
    elsif program && (current_section = user.current_section_in_program(program, session))
      student_dashboard_path(current_section)
    elsif program && user.accessible_program?(program)
      no_section_student_path
    else
      ua_home_path
    end
  end

  private def no_section_student_path
    if program&.supersite_junior?
      jr_section_program_content_path(section_id: 0, program_id: program.id)
    else
      no_section_student_dashboard_path(0, program.id)
    end
  end

  private def student_dashboard_path(target_section)
    path_args = { course_id: target_section.course_id, section_id: target_section.id }
    if program&.supersite_junior?
      jr_course_section_path(path_args)
    else
      course_section_path(path_args)
    end
  end
end
