class InstructorResourceFinder
  include BaseResourceFinder

  def initialize(instructor, program, opts = {})
    @instructor = instructor
    @program = program
    @opts = opts
  end

  def base_scope
    builder = super
    builder.vhl_resource_or_uploaded_by_user(@instructor)
  end
end
