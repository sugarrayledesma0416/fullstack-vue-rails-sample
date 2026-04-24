class InstitutionAdmin::CourseTemplatesController < Instructor::CoursesController
  include TemplateFocusable
  skip_before_action :require_course_owner

  def course_update(course, update_params)
    updater = Enterprise::CourseUpdater.new(course, update_params.merge(course_update_extra_params))
    updater.update
  end

  private def assign_course
    @course = Course.enterprise.find(params[:id])
  end

  private def course_params
    super.merge(
      params.require(:course).permit(
        :hide_from_instructor_dashboard,
        :owner_id
      )
    )
  end

  private def enterprise_section_params
    params.require(:section).permit(:class_days).merge(
      name: "Enterprise Section: #{course_params[:name]}",
      instructor_id: course_params[:owner_id],
      is_enterprise: true,
      time_zone: assign_school&.time_zone || 'Eastern Time (US & Canada)',
      due_time: '11:59PM'
    )
  end

  private def course_creation_extra_params
    base_params = super.except(:owner_id)

    base_params.merge(
      is_enterprise: true,
      creator_guid: current_user.guid,
      enterprise_section_attributes: enterprise_section_params
    )
  end

  private def course_update_extra_params
    super.except(:owner_id).merge(
      enterprise_section_attributes: enterprise_section_params.merge(id: @course.enterprise_section.id)
    )
  end
end
