class Instructor::AssignmentSetsController < RequireInstructorController
  before_action :assign_menu_coords, only: :index
  before_action :course_focus_redirect, only: :index
  before_action :redirect_if_assistant

  layout 'music_v1/responsive'

  def index
    @section = current_focus.section
    @assignments = AssignmentSetList.new(@section).entries
  end

  def create
    assignment_set = build_assignment_set
    if assignment_set.save
      render json: { assignment_set: { id: assignment_set.id } }
    else
      render(
        json: { errors: assignment_set.errors.full_messages },
        status: :unprocessable_entity
      )
    end
  end

  def update
    updater = AssignmentSetUpdater.new(params[:id], safe_params).update

    if updater.valid?
      head :ok
    else
      render(json: { errors: updater.errors }, status: :unprocessable_entity)
    end
  end

  def destroy
    AssignmentSet.find(params[:id]).destroy
    head :ok
    # TODO: Check permissions. If permissions are invalid, respond with:
    # render(
    #   json: { errors: 'You do not have permissions to remove the assignment set },
    #   status: :unprocessable_entity
    # )
  end

  def course_focus_redirect
    unless current_focus.focused_on_section?
      redirect_to(
        instructor_focus_selector_path(
          program_id: params[:program_id],
          feature_type: 'assignment sets'
        )
      )
    end
  end

  def export
    respond_to do |format|
      format.csv do
        assignment_set_list = AssignmentSetList.new(current_focus.section)
        send_data(
          assignment_set_list.to_csv(
            start_date: params[:start_date],
            end_date: params[:end_date]
          ),
          filename: 'assignment_sets.csv'
        )
      end
    end
  end

  private def assign_menu_coords
    @menu_location = 'content'
  end

  private def build_assignment_set
    AssignmentSet.new(
      safe_params.slice(:due_date, :section_id).merge(
        activities_attributes: (safe_params[:activities] || [])
      )
    )
  end

  private def safe_params
    params.require(:assignment_set).permit(
      :due_date,
      :section_id,
      activities: %i[activity_id assignment_set_rank]
    ).to_h.deep_symbolize_keys
  end

  private def update_assignment_set_activities
    AssignmentSet.find(params[:id]).tap do |memo|
      # TODO: Transaction may not be necesssary if Rails validates all records
      # before attempting to save any.
      AssignmentSet.transaction do
        memo.activities = safe_params[:activities].map do |activity_entry|
          AssignmentSetActivity.new(activity_entry)
        end
      rescue ActiveRecord::RecordNotSaved
        memo.errors.add(:activities, 'is invalid')
        raise ActiveRecord::Rollback
      end
    end
  end
end
