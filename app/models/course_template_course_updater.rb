class CourseTemplateCourseUpdater
  def initialize(params)
    @course_id = params[:course_id]
    @course_name = params[:name]
    @new_course_owner_id = params[:owner_id].to_i
    @source_template_id = params[:source_template_id]
    @hide_from_dash_checkbox_status = params[:hide_from_dash_checkbox_status]

    return if validation_errors.empty?

    raise validation_errors
  end

  def update_course
    course = Course.find(@course_id)

    # Save old owner ID for later use.
    @old_course_owner_id = course.owner_id

    # TODO: validate that course owner is an instructor with access to program in
    #       school

    # Start by updating the course.
    # `Course#hide_from_instructor_dash` depends on
    # hide_from_instructor_dashboard being set here.
    update_course_record(course)

    # Move section-instructor records from old owner to new owner.
    # `Course#hide_from_instructor_dash` depends on the existence of
    # section-instructor records for the correct owner.
    if @new_course_owner_id != @old_course_owner_id
      update_sections(course)
      update_section_instructors
    end

    # Now that the state for course and section instructors is updated,
    # we can update the 'hide' flag on the owner's section instructor records.
    course.hide_from_instructor_dash(@hide_from_dash_checkbox_status)
  end

  private def validation_errors
    error_messages = []

    if Course.where(id: @course_id).empty?
      error_messages << "There is no course with id = #{@course_id}."
    end

    error_messages.join("\n")
  end

  private def update_sections(course)
    course.sections.each { |section| section.update!(instructor_id: course.owner_id) }
  end

  private def update_section_instructors
    section_instructors_for_course = SectionInstructor
                                     .joins(:section)
                                     .where(sections: { course_id: @course_id })

    remove_instructor_role_records(section_instructors_for_course, @old_course_owner_id)
    add_or_update_instructor_role_records(section_instructors_for_course, @new_course_owner_id)
  end

  private def remove_instructor_role_records(section_instructors, user_id)
    section_instructors
      .where(role: 'Instructor')
      .where(user_id: user_id)
      .delete_all
  end

  private def add_or_update_instructor_role_records(section_instructors, user_id)
    existing_records_for_new_owner = section_instructors.where(user_id: user_id)

    # If any section instructor records exist for new owner,
    #   update role to be 'Instructor'.
    if existing_records_for_new_owner.any?
      existing_records_for_new_owner.update(role: 'Instructor')
    # Otherwise, create records for new owner for each section
    #   with role = 'Instructor'.
    else
      SectionInstructor.create(Section.where(course_id: @course_id).map do |section|
                                 { section_id: section.id,
                                   user_id: user_id,
                                   role: 'Instructor' }
                               end)
    end
  end

  private def update_course_record(course)
    course.update!(
      name: @course_name,
      owner_id: @new_course_owner_id,
      source_template_id: @source_template_id,
      hide_from_instructor_dashboard: @hide_from_dash_checkbox_status
    )
  end
end
