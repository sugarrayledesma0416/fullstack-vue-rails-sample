class RequireInstructorController < ApplicationController
  before_action :require_user
  before_action :require_instructor
  before_action :set_current_program
  before_action :require_program_access
  before_action :set_current_focus
  before_action :assign_course_sections_and_students_from_focus
  before_action :archived_program_redirect

  def validate_and_assign_return_to
    if params[:return_to].blank?
      referrer_uri = request.referrer.present? && URI.parse(request.referrer).request_uri
      if referrer_uri && (referrer_uri =~ /^\/gradebook\/\d+/)
        @return_to = referrer_uri
      else
        @return_to = gradebook_path(current_program)
      end
    else
      @return_to = params[:return_to]
    end
  end

  # Check to make sure the entire class has the proper access.
  # This method is used to determine if an error icon should
  # be shown in the Gradebook Subnav for the roster page by
  # both M3::RosterController and GradebookEngine::SectionController.
  def check_access(decorated_students = nil)
    @has_access_problem =
      if decorated_students.nil?
        GradebookStudent.has_access_problem?(
          @students, current_program, current_focus.sections
        )
      else
        decorated_students.any? { |student| !student.sufficient_access? }
      end
  end

  def require_section_access
    # If there is a section ID, check that the user is an instructor in the section.
    #
    # This is used as a before_action in GradebookEngine::InstructorController, which
    #   inherits from this controller. It is not meant to be used as a before_action
    #   in m3.
    #
    # NOTE: Some of the controllers that inherit from GradebookEngine::InstructorController
    #   do not expect a section_id in the params, e.g. GradebookEngine::CourseController.

    redirect_paths = { 'Instructor' => main_app.instructor_dashboard_path(current_program),
                       'Student' => main_app.ua_home_path }

    # Check if there is a section in the params.

    if params[:section_id]
      # If there is, test that current user is in instructors for it

      section = Section.find(params[:section_id])
      unless section.has_instructor? current_user
        # If not, assign error to flash and redirect to dashboard

        flash[:error] = 'This page requires instructor access to the current section.'
        redirect_to redirect_paths[current_user.base_account_type]
      end
    end
  end

  # used by GradebookEngine::CourseController to limit the
  # gradebook section list for instructor team members
  def filter_gb_sections(gb_sections)
    return gb_sections if gb_sections.empty?

    permitted_sections = SectionInstructor.where(user_id: current_user,
                                                 section_id: gb_sections.map(&:id))
                                          .pluck(:section_id)
    gb_sections.select do |gbs|
      permitted_sections.include?(gbs.id)
    end
  end

  def require_course_access
    # If there is a course ID, check that the user is an instructor in a section
    #   within the course.
    #
    # This is used as a before_action in GradebookEngine::CourseController,
    #   which inherits indirectly from this controller.

    redirect_paths = { 'Instructor' => main_app.instructor_dashboard_path(current_program),
                       'Student' => main_app.ua_home_path }

    if params[:course_id]
      # If there is, test that current user is in instructors for it

      course = Course.find(params[:course_id])
      unless current_user.instructor? &&
             (course.owner_id == current_user.id ||
              current_user.sections.map(&:course_id).include?(course.id))
        # If not, assign error to flash and redirect to dashboard

        flash[:error] = 'This page requires instructor access to the current course.'
        redirect_to redirect_paths[current_user.base_account_type]
      end
    end
  end
end
