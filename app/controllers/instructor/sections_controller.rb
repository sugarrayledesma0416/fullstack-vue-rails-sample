class Instructor::SectionsController < RequireInstructorController
  before_action :redirect_to_local_url,
                if: -> { params[:guids].present? && params[:guids] },
                only: :new

  skip_before_action :set_current_focus,
                     :assign_course_sections_and_students_from_focus

  include HasHelp
  include TimeHandler

  before_action :contextual_help_url, only: %i[new create edit update]
  before_action :set_current_focus, only: :edit
  before_action :assign_external_assignemnt_copy_attrs, only: %i[create update]
  before_action :assign_presenter, only: %i[new edit update destroy]
  before_action :require_section_owner, only: %i[destroy edit update]

  # Since these endpoints render HTML and then call themselves to render JSON,
  # the browser caches the JSON, and incorrectly displays it when the user
  # hits back/forward.
  before_action :set_cache_buster, only: %i[new edit]

  def show
    respond_to do |format|
      format.html { head :forbidden }
      format.js do
        render partial: 'instructor/sections/section_hover',
               locals: { section: Section.find(params[:id]) }
      end
    end
  end

  def new
    raise 'Course ID is invalid' unless params[:course_id]

    respond_to do |format|
      format.html { render layout: 'music_v1/default' }
      format.json do
        render_section_options(@presenter.previous_sections_for_course)
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        @course = Course.including_templates.find_by(id: base_params[:course_id])
        @section = Section.new(
          section_params.merge(
            course_id: @course.id,
            instructor_id: current_user.id
          )
        )

        if @section.save
          assignment_copy if @assignment_copy_id.present?
          set_focus_after_creation(@course)
          if @section.course.course_share_to_portfolio?
            Portfolio::CreateGroupWorker.perform_async(
              @section.id,
              section_params['section_instructors_attributes'].pluck('user_id')
            )
          end
          flash[:notice] = 'Your new section has been created.'
          render(
            json: {
              redirect_to: instructor_dashboard_url(program_id: @course.program_id)
            },
            status: :created
          )
        else
          flash[:error] = 'Section could not be created.'
          render_json_errors(@section.errors.messages, 422)
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.html { render layout: 'music_v1/default' }
      format.json do
        previous_sections = @presenter.previous_sections_for_course
                                      .reject { |section| section.name == @presenter.section.name }
        render_section_options(previous_sections)
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        @presenter.section.update(section_params)

        if @presenter.section.errors.empty?
          assignment_copy if @assignment_copy_id.present?
          @presenter.section.section_instructors.reload
          if @presenter.section.course.course_share_to_portfolio?
            Portfolio::UpdateGroupWorker.perform_async(
              @presenter.section.id
            )
          end
          flash[:notice] = 'Section has been successfully updated.'
          render_section_options(@presenter.previous_sections_for_course)
        else
          render_json_errors(@presenter.section.errors, 422)
        end
      end
    end
  end

  private def render_section_options(previous_sections)
    @presenter.build_additional_instructors
    render(
      json: SectionOptions.new(
        current_user, @presenter.section, previous_sections
      ),
      serializer: SectionOptionsSerializer,
      root: false
    )
  end

  def destroy
    section = @presenter.section
    course = section.course
    school = course.school
    section_archiver = SectionArchiver.new
    success = section_archiver.archive(section)
    if success
      if course.course_share_to_portfolio?
        Portfolio::DeleteGroupWorker.perform_async(section.guid, school.id)
      end
      flash[:notice] = section_archiver.success_message
    else
      flash[:error] = section_archiver.error_message
    end
    # For section templates, we make an AJAX request to this action as an endpoint
    # and need a JSON response.
    #
    # For regular sections, we navigate to this action and redirect afterward.
    if section.is_template?
      render json: { status: :ok }
    else
      redirect_to instructor_dashboard_path(current_program)
    end
  end

  def section_information_step
    render layout: nil
  end

  def class_days_step
    render layout: nil
  end

  private def base_params
    params.permit(:course_id, :id)
  end

  private def section_params
    params.require(:section)
          .permit(
            :additional_info,
            :class_days,
            :copy_external_assignments,
            :due_time,
            :hide_owner_name,
            :name,
            :open_to_students,
            :time_zone,
            :assignment_copy_section_id,
            :days_to_show_assignment_due_date,
            section_instructors_attributes: %i[
              allowed_to_edit_content
              id
              role
              section_id
              user_id
              _destroy
            ]
          )
  end

  private def assign_external_assignemnt_copy_attrs
    @assignment_copy_id = (params[:section] || {}).delete(:assignment_copy_section_id)
    @copy_external_assignments = (params[:section] || {}).delete(:copy_external_assignments)
  end

  private def assignment_copy
    section_id = params[:id] || @section.id
    copier = SectionAssignmentCopier.new(@assignment_copy_id, section_id)
    copier.copy_assignments

    return unless @copy_external_assignments

    # NOTE: We assume that the source and destination sections here belong to the same course.
    GradebookEngine::GradebookAPI.copy_external_assignments(
      @assignment_copy_id, section_id
    )
  end

  private def assign_presenter
    sec_params = if %w[new edit destroy].include?(action_name)
                   base_params
                 else
                   section_params.merge(base_params)
                 end

    @presenter = SectionsPresenter.new(
      current_user,
      current_program,
      sec_params
    )
  end

  private def redirect_to_local_url
    course_id = Course.by_guid(params[:course_id]).id

    redirect_to new_instructor_course_section_url(
      course_id: course_id,
      program_id: params[:program_id]
    )
  end

  private def render_json_errors(messages, status)
    render json: { errors: { section: messages } }, status: status
  end

  SECTION_OWNER_REQUIRED_MESSAGE = 'You must be the owner of the section ' \
                                   '(or course) to make changes.'.freeze

  private def require_section_owner
    return if owner_or_permitted_additional_co_instructor?

    respond_to do |format|
      format.json do
        render_json_errors([SECTION_OWNER_REQUIRED_MESSAGE], :forbidden)
      end
      format.html do
        flash[:error] = SECTION_OWNER_REQUIRED_MESSAGE
        redirect_to instructor_dashboard_path(program_id: current_program.id)
      end
    end
  end

  private def owner_or_permitted_additional_co_instructor?
    section = @presenter.section
    return true if current_user == section.instructor

    return false unless params[:section].present? && section_params.key?(:open_to_students)

    section.additional_co_instructor?(current_user)
  end
end
