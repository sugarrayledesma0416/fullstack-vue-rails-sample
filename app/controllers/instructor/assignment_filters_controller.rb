class Instructor::AssignmentFiltersController < RequireInstructorController
  # TODO: create action is unreachable. Should be removed along with route.
  def create
    create_or_update
  end

  def update
    create_or_update
  end

  private

  def create_or_update
    filter = AssignmentFilter.find_or_initialize_by(
      user_id: current_user.id, course_id: current_focus.course.id
    )
    filter.update!(safe_assignment_filter_params(params))

    new_assignments_path = current_focus.course.is_enterprise? ?
      institution_admin_new_assignment_template_path(
        current_program.id,
        current_focus.course.id,
        current_focus.section.id
      ) :
      instructor_new_assignments_path(current_program.id)

    redirect_to new_assignments_path
  end

  def safe_assignment_filter_params(params)
    params.require(:assignment_filter).permit(
      :activity_type,
      :category_id,
      :component,
      :content_type,
      :day,
      :grading_method,
      :lesson_id,
      :previous_section_id,
      :toc_entry_location,
      :week
    ).merge(
      day: if params[:assignment_filter][:previous_section_id].blank?
             ''
           else
             params[:assignment_filter][:day]
           end
    )
  end
end
