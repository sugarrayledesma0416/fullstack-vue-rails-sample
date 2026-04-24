class ActivityAssignmentsController < RequireInstructorController
  include ApplicationHelper
  before_action :redirect_if_assistant
  before_action :detect_institution_admin_context, only: [:update]

  def update
    assignment_processor = AssignmentUpdateProcessor.new(
      params,
      current_user,
      current_focus,
      institution_admin_context: @institution_admin_context
    )
    assignment_processor.process

    session[:activity_assignment] = assignment_processor.update_session_due_date_and_category
    if assignment_processor.success.any?
      flash[:notice] = assignment_processor.flash_notice_msg
      session[:preferred_assignment_date] = params[:activity_assignment][:due_date]
      respond_to do |format|
        format.js do
          if params[:source] && params[:source] == 'gradebook'
            head :ok
          elsif params[:source] && params[:source] == 'calendar'
            render :json => {load_rank_list: false}
          elsif params[:source] && params[:source] == 'standards'
            flash.discard
            render json: { is_standards_assigning: true }
          else
            # Temporarily removing the rank listing function until we debug the workset ranks
            # not being set correctly
            # render :json => {load_rank_list: assignment_processor.display_rank_modal?, due_date: params[:activity_assignment][:due_date], section_id: current_focus.section.id, toc_location: assignment_processor.toc_location }
            render :json => {load_rank_list: false, due_date: params[:activity_assignment][:due_date], section_id: current_focus.section.id, toc_location: assignment_processor.toc_location }
          end
        end
      end
    else
      flash.now[:error] = 'Changes to assignment failed'
      respond_to do |format|
        format.js do
          render plain: error_messages_for_modal(assignment_processor.failure.first), status: 422
        end
      end
    end
  end

  private def detect_institution_admin_context
    @institution_admin_context = request.referrer&.include?('/institution_admin/') || false
  end
end
