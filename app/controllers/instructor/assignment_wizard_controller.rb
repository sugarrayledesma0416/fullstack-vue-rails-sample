class Instructor::AssignmentWizardController < RequireInstructorController
  def index
    @course = find_course(params[:course_id])
    render layout: 'wizard_layout'
  end

  def course_info
    course = find_course(params[:course_id])
    course_options = CourseOptions.new(current_user, course, program)

    json_response = {
      current_course: course.id,
      name: course.name,
      start_date: course.start_date,
      end_date: course.end_date,
      has_assignments: course.assignments.count > 0,
      setup_descriptions: course_options.setup_descriptions,
      previous_courses: course_options.previous_course_and_section_data(@in_institution_admin),
      categories: course.categories.map do |c|
        {
          id: c.id,
          name: c.name
        }
      end,
      unit_label: program.unit_label
    }

    render json: json_response
  end

  def create
    result = AssignmentWizardCopier.call(params)

    if result.success?
      render json: { job_ids: result.job_ids }
    else
      render json: { error: result.message }, status: 500
    end
  end

  private def find_course(course_id)
    Course.find(course_id)
  end
end
