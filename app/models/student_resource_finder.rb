class StudentResourceFinder
  include BaseResourceFinder

  def initialize(program, section, opts = {})
    @program = program
    @section = section
    @opts = opts
  end

  def base_scope
    builder = super
    if @section.present? && @section.instructor.present?
      # if the student is in a section, check to see if it assigned,
      # or if the instructor has set a visibility setting
      builder = builder.visible_by_instructor(@section.instructor, @section)
    else
      # just check that vhl_student_resource is true
      builder = builder.visible_to_students
    end
    # never show protected resources!
   builder = builder.unprotected
   builder
  end
end
