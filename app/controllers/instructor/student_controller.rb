class Instructor::StudentController < RequireInstructorController
  skip_before_action :set_current_focus, :assign_course_sections_and_students_from_focus
  before_action :assign_section, only: %i[search search_by]

  def search
    @return_to = params[:return_to]
    @page_header = 'student<span>search</span>'
    @section_id = params[:section_id]
    render partial: 'search'
  end

  def search_by
    presenter = AddableStudentsPresenter.new(current_user.schools, current_program, params)
    concurrent_enrollment_enabler = EnrollmentEngine::ConcurrentEnrollmentEnabler.new(
      course_to: @section.course,
      enroll_by: EnrollmentEngine::ENROLL_BY_INSTRUCTOR
    )
    @single_enrollment_enforced = concurrent_enrollment_enabler.enforce_single_enrollment?

    render partial: 'search_results', locals: { presenter: }
  end

  private def assign_section
    @section = Section.find(params[:section_id])
  end
end
