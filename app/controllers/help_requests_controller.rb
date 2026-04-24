class HelpRequestsController < ApplicationController
  before_action :require_user
  before_action :require_program_access, only: :index
  before_action :assign_menu_coords
  before_action :archived_program_redirect

  def index
    @presenter = HelpRequestsPresenter.new(current_section, current_user, params[:status]&.strip_tags).populate
    @page_title = 'Instructor Help Requests'
  end

  def assign_menu_coords
    @menu_location = 'communication'
  end

  def activity_index
    help_requests = current_user.help_requests.instructor_respondable_by_section_and_activity(params[:section_id], params[:activity_id]).include_users
    render json: help_requests.to_json(HelpRequest::ACTIVITY_JSON_OPTIONS)
  end

  def create
    submitter = HelpRequestSubmitter.new(current_user, safe_help_request_params, request.env).submit
    render json: submitter.result.to_json, status: submitter.status
  end

  def destroy
    current_user.help_requests.find(params[:id]).destroy
    head :ok
  end

  def update
    help_request = current_user.help_requests.find(params[:id])
    attributes = { read_by_student: params[:read_by_student] } # The only update that should be happening on the student side
    help_request.update!(attributes)
    head :ok
  end

  private def safe_help_request_params
    help_request_params = params.require(:help_request_data).permit(
      :activity_id,
      :activity_state,
      :cms_activity_id,
      :cms_revision_id,
      :http_referer,
      :program_id,
      :section_id,
      request_params: %i[action controller section_id id]
    )

    params.permit(
      :activity_form_contents,
      :flash_version,
      :helpable_item_id,
      :helpable_item_type,
      :request_type,
      :severity_level,
      :student_comment
    ).merge(help_request_params)
  end
end
