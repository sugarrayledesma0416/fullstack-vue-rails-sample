class InstitutionAdmin
  class CoursesController < Instructor::CoursesController
    before_action :set_in_institution_admin, only: %i[new edit]
    before_action :set_in_course_wizard_institution_admin, only: %i[new edit]
    layout 'application_v3'

    before_action(
      :require_user,
      :require_enterprise_admin,
      :assign_no_program_bar,
      :require_institution_admin
    )

    def new
      course = Course.new(new_course_params)
      # This view has a dynamic h1 header, so the normal @page_title
      # variable needs to be unset so the layout doesn't render an
      # extra h1. The h1 will be set by a Vue app.
      @page_title = nil

      respond_to do |format|
        format.html do
          assign_potential_instructors(course)
          render layout: 'music_v1/responsive'
        end
        format.json do
          render json: CourseOptions.new(
            current_user, course, current_program, selected_school_id
          ), serializer: CourseOptionsSerializer
        end
      end
    end

    def edit
      course = Course.enterprise.find(params[:id])
      # This view has a dynamic h1 header, so the normal @page_title
      # variable needs to be unset so the layout doesn't render an
      # extra h1. The h1 will be set by a Vue app.
      @page_title = nil

      respond_to do |format|
        format.html do
          assign_potential_instructors(course)
          render layout: 'music_v1/responsive'
        end
        format.json do
          render json: CourseOptions.new(
            current_user, course, current_program, selected_school_id
          ), serializer: CourseOptionsSerializer
        end
      end
    end

    def content_step
      respond_to do |format|
        @course = Course.enterprise.find(params[:id])

        format.json do
          render json: {
            course_has_individual_assignments: @course.has_individual_assignments?
          }
        end
      end
    end

    private def assign_potential_instructors(course)
      @potential_instructors = course.prospective_additional_instructors.select(
        'id, first_name, last_name, email'
      ).to_a
    end

    private def new_course_params
      super.merge(is_enterprise: true)
    end

    private def assign_no_program_bar
      @no_program_bar = true
    end

    private def set_in_institution_admin
      @in_institution_admin = true
    end

    private def set_in_course_wizard_institution_admin
      @in_course_wizard_institution_admin = true
    end

    private def require_course_owner
      # Ensures that only the course owner or an admin of the associated school
      # can access or modify the course.
      return if course_owned_by_user? || user_is_admin_of_school_and_program?

      super
    end

    private def course_owned_by_user?
      @course.owned_by?(current_user)
    end

    private def user_is_admin_of_school_and_program?
      current_user.school_program_admin_users.exists?(
        school_id: params[:school_id].to_i,
        program_id: current_program.id
      )
    end
  end
end
