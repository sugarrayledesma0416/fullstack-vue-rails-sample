class InstitutionAdmin::DashboardController < ApplicationController
  before_action :require_user, :require_enterprise_admin, :assign_no_program_bar
  before_action :assign_presenter, except: %i[create_sections delete_course update_section delete_section]
  before_action :require_institution_admin, except: %i[index section_metrics section_metrics_data]
  before_action :set_admin_schools, only: %i[
    index
    section_metrics
    configure_view
    delete_course
    delete_section
    open_enrollment_section
    close_enrollment_section
  ]
  before_action :set_school, only: %i[
    section_metrics
    configure_view
    delete_course
    delete_section
    open_enrollment_section
    close_enrollment_section
  ]
  before_action :assign_program_and_year, only: %i[courses sections]
  layout 'music_v1/responsive'
  include TemplateFocusable

  def index
    @show_institution_admin_header = true
    @admin_district = @admin_schools.first&.district
    @selected_school = params[:school_id] ? School.find(params[:school_id]) : @admin_schools.first
  end

  def courses
    return if @presenter.courses.blank?

    @selected_course = @presenter.courses.first
    @sections = @selected_course.sections
  end

  def sections
    @course = @presenter.course
    @sections = @course.sections
  end

  def section_data
    render json: @presenter.section_data(params[:course_id].to_i)
  end

  def section_metrics
    @presenter.assign_school(@school.id)
  end

  def section_metrics_data
    render json: @presenter.section_metrics_data(params[:section_id].to_i)
  end

  def roster_dashboard
    @section = Section.find params[:section_id]
    @course = @section.course
    @school_id = @course.school_id
    @program = @course.program
    @grace_periods = GracePeriodAllocation.new(@school_id)
    @roster_presenter = RosterPresenter.new(@section.id, @program)
    year = @course.start_date.year
    # you get roster page from courses, past_courses or progress view
    # and it is set in params[:roster_origin]
    @return_path =
      institution_admin_sections_path(
        course_id: @section.course.id,
        program_id: @course.program.id,
        school_id: @school_id
      )
    #This is required to drop and email student on roster page
    #app/controllers/focus_assignment.rb takes course and section values from session.
    session.merge!( focus: { @program.id.to_s => { 'course_id' => @course.id,
                                                   'section_id' => @section.id }
                           }
                  )
    render layout: 'application_v3'
  end

  def course_template_data
    # Use `find_by` instead of `find`: if the template has been deleted,
    # it will return `nil` instead of raising an exception.
    #
    # The presenter returns a sensible default data structure if the value
    # is `nil`.
    @course_template = Course.templates.find_by(id: params[:template_id])

    render json: @presenter.course_template_data(@course_template)
  end

  def section_template_data
    render json: @presenter.section_template_data(params[:template_id])
  end

  def create_course
    course_params = params.permit(
      :name,
      :owner_id,
      :source_template_id,
      :hide_from_dash_checkbox_status
    )
    course_id = CourseTemplateCourseCreator.new(course_params.merge(current_user: current_user)).create_course
    flash[:notice] = "Course <b>#{course_params[:name]}</b> was created successfully."

    render json: {
      course_id: course_id,
      status: :ok
    }
  end

  def update_course
    course_params = params.permit(
      :course_id,
      :name,
      :owner_id,
      :source_template_id,
      :hide_from_dash_checkbox_status
    )
    CourseTemplateCourseUpdater.new(course_params).update_course

    flash[:notice] = "Course <b>#{course_params[:name]}</b> was updated successfully."

    render json: {
      # Return the course ID so that course can be selected in Courses tab.
      course_id: course_params[:course_id],
      status: :ok
    }
  end

  def delete_course
    course_params = params.permit(:course_id, :school_id, :authenticity_token)
    course = @school.courses.enterprise.find(course_params[:course_id])

    if course.sections.present?
      flash[:error] = "You cannot delete <b>#{course.name}</b> because it has sections created."
      return redirect_to institution_admin_courses_current_path(program_id: course.program_id,
                                                        school_id: course.school_id)
    end

    course.archive
    flash[:notice] = "Course <b>#{course.name}</b> was deleted successfully."

    redirect_back(
      allow_other_host: false,
      fallback_location: institution_admin_courses_current_path(
        program_id: course.program_id,
        school_id: course.school_id
      )
    )
  end

  def section_options
    course = Course.find(params[:course_id])

    render json: {
      additional_instructor_options: @presenter.additional_instructor_options(course),
      course_owner_name: @presenter.course_owner_name(course),
      existing_section_names: @presenter.existing_section_names(course),
      section_template_options: @presenter.section_template_options(course)
    }
  end

  def new_section
    @section = Section.new(course: @presenter.course, instructor: @presenter.course.owner)

    render :section_wizard
  end

  def edit_section
    @section = Section.find_by!(id: params[:id], course_id: params[:course_id])

    render :section_wizard
  end

  def create_sections
    school = School.find_by(id: params[:school_id])

    if school.nil?
      render json: { error: 'School not found' }, status: :not_found
      return
    end

    params[:section][:additional_instructors].each do |ai|
      if ai["role"].blank?
        render json: { error: 'Additional instructors must have a role' }, status: :unprocessable_entity
        return
      end
    end

    course = school.courses.find_by(id: params[:course_id], is_enterprise: true)

    if course.nil?
      render json: { error: 'Course not found' }, status: :not_found
      return
    end

    result = Enterprise::SectionCreator.new(create_section_params, course).create_section

    section_name = "<strong>#{create_section_params[:name]}</strong>"
    course_name = course.name

    flash[:notice] = %(
      Section: <b>#{section_name}</b>
      for Course <b>#{course_name}</b>
      was created successfully.
    )

    if result[:uncopied_assignments]
      flash[:error] = %(
        Some assignments could not be copied because course settings have changed.
        This can happen if an assignment's due date falls outside of the course's
        date range, or if its category has been renamed or removed.
      )
    end

    render json: {
      status: :ok
    }
  end

  def update_section
    begin
      section = Section.non_enterprise.find(update_section_params[:section_id])

      if section.course.blank? || !section.course.is_enterprise?
        render json: { error: 'Section is not valid to be updated' }, status: :unprocessable_entity
        return
      end

      params[:section][:additional_instructors].each do |ai|
        if ai["role"].blank?
          render json: { error: 'Additional instructors must have a role' }, status: :unprocessable_entity
          return
        end
      end

      Enterprise::SectionUpdater.new(update_section_params, section).update_section

      flash[:notice] = %(
        Section <b>#{section.name}</b>
        for Course <b>#{section.course.name}</b>
        was updated successfully.
      )
      render json: {
        status: :ok
      }
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Section not found: #{e.message}" }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      error_message = "Invalid data provided: #{e.record.errors.full_messages.join(', ')}"
      render json: { error: error_message }, status: :unprocessable_entity
      VHLMonitor.error(
        error_message,
        update_section_params:,
        exception_message: e.message
      )
    rescue StandardError => e
      render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
    end
  end

  def open_enrollment_section
    section = Section.find(permitted_section_params[:id])

    if section.course.is_enterprise?
      update_section_open_to_students(section, true)
      flash[:notice] =
        "<b>#{section.name}</b> has been successfully updated and is now open for enrollment."
    else
      flash[:error] = "Section <b>#{section.name}</b> does not belongs to an enterprise course."
    end

    redirect_back_to_section(section.course.id, section.course.program.id)
  end

  def close_enrollment_section
    section = Section.find(permitted_section_params[:id])

    if section.course.is_enterprise?
      update_section_open_to_students(section, false)
      flash[:notice] =
        "The section <b>#{section.name}</b> has been successfully updated and is now close for enrollment."
    else
      flash[:error] = "Section <b>#{section.name}</b> does not belongs to an enterprise course."
    end

    redirect_back_to_section(section.course.id, section.course.program.id)
  end

  def delete_section
    section = Section.find(delete_section_params[:id])

    if section.course.is_enterprise?
      section.archive
      flash[:notice] = "Section <b>#{section.name}</b> was deleted successfully."
    else
      flash[:error] = "Section <b>#{section.name}</b> does not belongs to an enterprise course."
    end

    redirect_back_to_section(section.course.id, section.course.program.id)
  end

  def hide_course_from_instructor_dash
    course = Course.find(params[:course_id])
    course.hide_from_instructor_dash(true)

    render json: {
      status: :ok
    }
  end

  def show_course_on_instructor_dash
    course = Course.find(params[:course_id])
    course.hide_from_instructor_dash(false)

    render json: {
      status: :ok
    }
  end

  def configure_view
    @hidden_courses = @presenter.hidden_courses params[:program_id].to_i
  end

  def toggle_admin_show
    params.permit(:course_ids, :program_id)
    course_ids_to_hide = params[:course_ids]
    program = Program.find(params[:program_id].to_i)
    InstitutionAdminHiddenCourse.hide_courses(current_user, program, course_ids_to_hide)

    flash[:notice] = 'Courses where updated successfully.'
    render json: { status: :ok }
  end

  private def redirect_back_to_section(course_id, program_id)
    redirect_back(
      allow_other_host: false,
      fallback_location: institution_admin_sections_path(
        course_id:,
        program_id:,
        school_id: @school.id
      )
    )
  end

  private def set_admin_schools
    @admin_schools = current_user.admin_schools
  end

  private def set_school
    @school = @admin_schools.find(params[:school_id])
  end

  private def base_section_params
    [
      :id,
      :course_id,
      :school_id,
      :hide_owner_name,
      :name,
      :days_to_show_assignment_due_date,
      :due_time,
      :open_to_students,
      :time_zone,
      :open_to_students,
      :days_to_show_assignment_due_date,
      additional_instructors: [:instructor_id, :role, :show]
    ]
  end

  private def permitted_section_params(extra_keys = [])
    params.require(:section).permit(base_section_params + extra_keys)
  end

  private def update_section_params
    permitted_section_params([:section_id])
  end

  private def create_section_params
    permitted_section_params
  end

  private def delete_section_params
    permitted_section_params( [:authenticity_token])
  end

  # this is set to prevent the program bar from appearing on the admin screens
  private def assign_no_program_bar
    @no_program_bar = true
  end

  private def assign_presenter
    @presenter ||= InstitutionAdminDashboardPresenter.new(current_user, params[:school_id], params[:program_id], params[:year], params[:course_id])
  end

  private def assign_program_and_year
    @program = Program.find params[:program_id]
    @year = params[:year] || Time.zone.today.year
  end

  private def update_section_open_to_students(section, flag_attribute)
    begin
      section.update!(open_to_students: flag_attribute)
    rescue ActiveRecord::RecordInvalid => e
      VHLMonitor.notify(e)
      Rails.logger.error("Failed to update section: #{e.message}")
    end
  end
end
