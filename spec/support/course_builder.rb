module CourseBuilder
  # create a course with stubbed ids to minimize db record creation
  # values passed in the opts hash should be ids, not objects

  def create_course_with_stubs(opts = {})
    program = build_object(:program, opts)
    first_unit = build_object(:first_unit, opts, :unit, program: program)
    last_unit = build_object(:last_unit, opts, :unit, program: program)

    create(
      :course,
      first_unit: first_unit,
      last_unit: last_unit,
      owner: build_object(:owner, opts, :instructor),
      program: program,
      school: build_object(:school, opts)
    )
  end

  private def build_object(object, opts, factory_name = nil, params = {})
    factory_name ||= object
    object_id ||= "#{object.to_s}_id".to_sym
    # First see if there's an object in the opts hash
    # Next try to use opt[object_id] to build a new object
    # Finally build a new object
    opts[object] || 
   (opts[object_id] && build_stubbed(factory_name, {id: opts[object_id]}.merge(params))) || 
    build_stubbed(factory_name, params)
  end
end
