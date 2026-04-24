class ResourcesController < ApplicationController
  before_action :require_user
  before_action :require_program_access
  before_action :assign_menu_coords
  before_action :require_instructor_or_grader, only: %i[new create]
  before_action :set_page_header
  before_action :archived_program_redirect

  include HasHelp
  before_action :contextual_help_url, only: :index

  include SectionHeader
  include ResourceHelper
  include Uploadable::Controller
  include ActionController::Streaming
  include Zipline

  before_action :assign_section_header, only: :index, if: :current_user_is_student?
  before_action :assign_presenter, only: %i[index new create edit update]

  before_action :set_current_program
  before_action :set_current_focus, if: :current_user_is_instructor?
  before_action :assign_start_unit_id, only: %i[new edit]
  before_action :assign_course_sections_and_students_from_focus,
                only: %i[index update ajax_resources],
                if: :current_user_is_instructor?

  before_action :require_editing_rights, only: %i[edit update]

  def set_page_header
    @page_header = 'Resources'
  end

  def index
    @page_header = 'Resources'
    @section = current_section
    assign_return_url
    render layout: 'layouts/music_v1/responsive'
  end

  def new
    @page_header = 'Add a Resource'
    @resource = Resource.new(program_id: params[:program_id], start_unit_id: @start_unit_id)
    assign_component_options
    assign_unit_options
    render :new, layout: 'wizard_layout'
  end

  def create
    creator = ResourceCreator.new(current_user, resource_params).create
    @return_to = params[:return_to]
    @resource  = creator.resource

    if creator.successful?
      flash[:notice] = 'New resource created'
      assign_return_to_that_shows_this_resource
      redirect_to @return_to
    else
      assign_component_options
      assign_unit_options
      @detected_virus_name = creator.detected_virus_name
      set_detected_virus_error_if_detected
      @page_header = 'Add a Resource'
      render :new, layout: 'wizard_layout'
    end
  end

  def edit
    @page_header = 'Edit a Resource'
    assign_component_options
    assign_unit_options
    render :edit, layout: 'wizard_layout'
  end

  def update
    if @sections.empty?
      @section_id = '0'
    else
      @section_id = @sections.first.id
      @section = Section.find_by_id(@section_id)
    end

    old_component_id = @resource.resource_component_id
    old_start_unit_id = @resource.start_unit_id
    updater = ResourceUpdater.new(current_user, resource_params, @resource).update
    @resource = updater.resource
    @return_to = params[:return_to]

    if updater.successful?
      assign_return_to_that_shows_this_resource if (@resource.resource_component_id_changed? && @resource.start_unit_id_changed?)
      flash[:notice] = 'Your changes to the resource were saved.'
      redirect_to @return_to
    else
      @page_header = 'Edit a Resource'
      @detected_virus_name = updater.detected_virus_name
      set_detected_virus_error_if_detected
      @return_to = params[:return_to].to_s.gsub(' ', '&')
      assign_component_options
      assign_unit_options
      render :edit, layout: 'wizard_layout'
    end
  end

  def destroy
    @resource = Resource.find(params[:id])
    @return_to = params[:return_to].to_s.gsub(/[ +]/, '&')
    if @resource.update!(is_archived: true)
      destroy_resources_instructor_settings
      unassign_resources_assignments
      flash[:notice] = "Resource '#{@resource.title}' has been deleted."
    else
      flash[:error] = "Resource '#{@resource.title}' could not be deleted."
    end
    redirect_to @return_to
  end

  def ajax_resources
    # TODO: jhon - Are we still calling this from activity_assignments ??
    # if not, remove all of this and the erb located at activity_assignments
    if @sections.empty?
      @section_id = '0'
    else
      @section_id = @sections.first.id
      @section = Section.find_by_id(@section_id)
    end
    @return_to = params[:return_to]
    page = params[:page].blank? ? 1 : params[:page]
    search_results = Resource.find_all_for_user_and_section(current_program, current_user, params, @section)
    @resources = search_results.paginate(page: page, per_page: 50)
    @assignments = Assignment.activity_assignments(@section, @resources) if @section
    render partial: 'activity_assignments/resources_list', locals: {
      resources: @resources,
      section: @section,
      sections: @sections,
      current_user: current_user,
      assignments: @assignments,
      return_to: @return_to
    }
  end

  def download
    @resource = current_user.downloadable_resource(params[:id], current_program, current_section)
    redirect_to @resource.signed_url
  end

  def download_multiple
    resource_finder = if current_user.instructor?
                        InstructorResourceFinder.new(current_user, current_program)
                      else
                        StudentResourceFinder.new(current_program, current_section)
                      end
    selected_resources = resource_finder.base_scope.where(
      id: params[:selected_resources].split(',')
    )
    # zipline() will stream a zip file to the personthat submitted the request.
    # In order for the data to be streamed as is needed we use a lazy map (.lazy.map), the lazy map
    # will only run the code inside of the map
    # block when the element is requested to be streamed by zip_line.
    # We also do an additional step to ensure that the file names are unique.
    zipline(file_mappings_for_download(selected_resources), 'downloaded_resources.zip')
  end

  private

  def destroy_resources_instructor_settings
    instructor_resource_settings = InstructorResourceSetting.find_by_user_id_and_resource_id(current_user.id, @resource.id)
    instructor_resource_settings.destroy_old_settings unless instructor_resource_settings.blank?
  end

  def unassign_resources_assignments
    @section = current_focus.section
    @assignments = Assignment.activity_assignments(@section, [@resource])
    @assignments.each do |assignment|
      assignment.unassign
    end
  end

  def assign_resource_header
    header = "#{@resource.resource_component.name}"
    header << " / #{@resource.subcomponent_name}" unless @resource.subcomponent_name.blank?
    header
  end

  def assign_start_unit_id
    @return_to = params[:return_to].to_s.gsub(' ', '&')

    start_unit_id_match = @return_to.match(/start_unit_id=(\d+)/)
    @start_unit_id = start_unit_id_match[1] if start_unit_id_match
  end

  def assign_presenter
    @presenter = ResourcesPresenter.new(
      current_user,
      current_section,
      current_program,
      presenter_params_hash
    )
  end

  def assign_return_to_that_shows_this_resource
    new_params = return_to_params
    new_params[:component_id] = @resource.resource_component_id
    new_params[:start_unit_id] = @resource.start_unit_id
    new_params[:page] = Resource.page_for_resource(
      @resource,
      current_user,
      new_params,
      @section
    )
    @return_to = instructor_program_resources_path(current_program) + '?' + new_params.to_query
  end

  def assign_component_options
    @component_list =  current_program.resource_components
    @selected_component_id = selected_component_id.to_i
  end

  def selected_component_id
    return_to_params[:component_id] || @resource.resource_component_id
  end

  def assign_unit_options
    @selected_unit = selected_unit || ''
  end

  def selected_unit
    multi_lesson_ids = @program.units.map(&:id).compact
    multi_lesson_params = multi_lesson_ids.inject('?') { |memo, id| memo << "start_unit_id[]=#{id}&" }
    if @resource.start_unit_id.present? && @resource.end_unit_id.present?
      instructor_program_resources_path(program) + multi_lesson_params
      # 'Multi-lesson'
    elsif @resource.start_unit_id.present? && @resource.end_unit_id.nil? && @resource.lesson_id.present?
      instructor_program_resources_path(program, lesson_id: @resource.lesson_id, start_unit_id: @resource.start_unit_id)
    else
      instructor_program_resources_path(program, start_unit_id: @resource.start_unit_id)
      # @resource.program.units[@resource.start_unit_id].title
    end
  end

  def return_to_params
    uri = URI.parse(@return_to)
    query_string ||= CGI.parse(uri.query) unless uri.query.blank?
    new_params = HashWithIndifferentAccess.new(query_string)
    # Override the default value of [] that the hash returned by CGI.parse sets.
    new_params.default = nil
    new_params.each { |key, value| new_params[key] = value.first.to_s }
    new_params
  end

  def assign_reset_url
    if current_user.instructor?
      @reset_url = instructor_program_resources_path(current_program)
    else
      @reset_url = resources_path(current_program, @section)
    end
  end

  def assign_return_url
    @return_to = request.fullpath.to_s.gsub('&', '+')
  end

  def filter_by_params?
    browse_or_search_keys = [:start_unit_id, :component_id, :search_string]
    browse_or_search_keys.any? { |key| params[key].present? }
  end

  def assign_menu_coords
    @menu_location = 'teaching'
  end

  def require_editing_rights
    @resource = Resource.find(params[:id])
    unless @resource.editable_by?(current_user)
      flash[:error] = 'You are not authorized to access this page.'
      redirect_to root_url
    end
  end

  def resource_params
    resource_params = params.require(:resource).permit(
      :description,
      :first_chapter,
      :first_lesson,
      :first_module,
      :first_section,
      :first_theme,
      :first_unit,
      :last_chapter,
      :last_lesson,
      :last_module,
      :last_section,
      :last_theme,
      :last_unit,
      :protected,
      :resource_component_id,
      :title
    )
    allowed_params = params.permit(
      :unit_options,
      :file_uploading,
      :resource_student_visibility,
      :start_unit_id,
      :end_unit_id,
      :program_id,
      :protected,
      :lesson_id,
      :uploaded_file,
      :return_to
    ).merge(resource: resource_params)
    if params[:uploaded_file].is_a?(ActionController::Parameters)
      allowed_params.merge(
        uploaded_file: params.require(:uploaded_file).permit(
          :filename, :infected, :virus_name
        )
      )
    else
      allowed_params
    end
  end

  # The start_unit_id param may be a single id or an array of ids.
  # Since there's no way to tell in advance which format will be received,
  # both cases need to be handled.
  private def presenter_params_hash
    if params[:start_unit_id].is_a?(Array)
      params.permit(:component_id, :lesson_id, start_unit_id: [])
    else
      params.permit(:component_id, :lesson_id, :start_unit_id)
    end.to_h.symbolize_keys
  end

  private def file_mappings_for_download(selected_resources)
    selected_resources.group_by(&:file_name).lazy.flat_map do |_key, resources_array|
      resources_array.map.with_index do |resource, index|
        file_name = if index.zero?
                      resource.file_name
                    else
                      extension_name = File.extname(resource.file_name)
                      base_name = File.basename(resource.file_name, extension_name)
                      "#{base_name} (#{index})#{extension_name}"
                    end
        [StringIO.new(resource.content_data), file_name]
      end
    end
  end
end
