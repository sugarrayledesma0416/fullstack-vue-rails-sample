# rubocop:disable Style/ClassAndModuleChildren
# We cannot use a module Instructor to for nesting b/c we also
# have a model named Instructor.
class Instructor::StandardsAssigningController < RequireInstructorController
  # rubocop:enable Style/ClassAndModuleChildren
  include StandardsAssigningSearchResults
  include ApplicationHelper

  before_action :prevent_unauthorized_access
  before_action :presenter

  def index
    @selected_unit = params[:selected_unit].presence
    preload_standards_filter
    flash.delete(:error)
    flash[:error] = @presenter.error_msg if @presenter.error_msg
  end

  def search_assets
    respond_to do |format|
      format.json do
        matched_assets_with_standards
      end
    end
  end

  def search_standards
    respond_to do |format|
      format.json do
        matched_standards
      end
    end
  end

  def search_standards_by_asset
    item = if params['item_type'] == 'EReaderItem'
             EReaderItem.find(params['asset_id'].to_i)
           else
             Activity.find(params['asset_id'].to_i)
           end
    @presenter.activity = item
    payload = @presenter.mapped_standards(current_focus.course)
    render json: { mapped_standards: payload }, status: :ok
  end

  def data_for_assigned_item
    @presenter.assignments_by_activity[activity_assigned.id] =
      activity_assigned.assignments.where(section_id: current_focus.sections.pluck(:id).uniq)

    render json: { data_for_assigned_item: assigned_item_data }, status: :ok
  end

  def browse_standards
    respond_to do |format|
      format.json do
        matched_standards_for_browse
      end
    end
  end

  private def assigned_item_data
    standard_assets = StandardAsset.find(params[:standard_asset_ids])
    standard_set_guids = params[:standard_set_guids]
    alignments = @presenter.fetch_alignments(standard_assets.pluck(:id), standard_set_guids)
    grouped_alignments = @presenter.grouped_alignments(alignments)

    @presenter.item(
      activity_assigned,
      standard_assets.first.reference_type,
      grouped_alignments.values.flatten.uniq
    ).tap do |item|
      item[:standardAssetIds] = params[:standard_asset_ids]
    end
  end

  private def activity_assigned
    Activity.find(params[:id]).tap do |memo|
      assigned_in_section = memo.assignments.where(
        section_id: current_focus.sections.pluck(:id)
      ).any?
      memo.instance_exec(assigned_in_section) do |assigned|
        @assigned = assigned
      end
    end
  end

  # We don't want the tool to be accessible unless the program supports standards
  # and the instructor or co-instructor has an open course and section in the program.
  # We do prevent access via menu item disabling, however someone could enter the route URL
  # directly so this will prevent access from there.
  private def prevent_unauthorized_access
    message = if current_program && !current_program.supports_standards?
                'Program must support standards'
              else
                standards_based_assigning_unauthorized_access_check(current_focus.course)
              end
    render(plain: message, status: :unauthorized) unless message.nil?
  end

  private def presenter
    @presenter = StandardsAssigningPresenter.new(
      current_program,
      current_focus.sections,
      current_focus.course,
      selected_standards: params['selected_standards'],
      standard_set_vendor_guid: params['standard_set_vendor_guid'],
      search_term: params['search_term'],
      selected_units: params[:selected_units],
      selected_skills: params[:selected_skills],
      selected_refinements: params[:selected_refinements],
      selected_content_type: params[:selected_content_type],
      standard_ids_for_init: params['standards'],
      next_key: params.dig(:next_key, :standard_asset_id) || ''
    ).tap do |memo|
      memo.assignment_validator =
        AssignmentValidator.new(current_user, current_focus.course, [])
      memo.vtext_linker =
        TeacherVtextLinker.new(current_program, current_user)
    end
  end
end
