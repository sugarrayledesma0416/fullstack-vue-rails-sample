class StudentInfoPresenter

  attr_accessor :student, :program

  def initialize(student, program, section = nil)
    self.student = student
    self.program = program
    @section = section
  end

  def student_full_name
    student.full_name
  end

  def section
    @section ||= student.current_section_in_program(program)
  end

  def section_name
    (section.name + (enrollment && enrollment.complete? ? ' (completed)' : '')).html_safe
  end

  def enrollment
    @enrollment ||= Enrollment.by_section_and_student(section, student).first
  end

  def course_name
    section.course_name
  end

  def thumbnail_path
    student.avatar_thumb_url
  end

end
