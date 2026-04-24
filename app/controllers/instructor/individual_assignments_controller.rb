class Instructor::IndividualAssignmentsController < RequireInstructorController
  COURSE_DISABLED_MESSAGE = 'You have not enabled Individual Assigning ' \
                            'for this course'.freeze

  before_action(
    :require_individual_assigning_to_be_enabled,
    :redirect_if_assistant,
    :assign_section_id,
    :assign_menu_coords
  )
  before_action :assign_presenter, only: %i[index export]

  layout 'music_v1/responsive'

  def index
    @page_title = 'Individual Assignment Management'

    unless current_focus.focused_on_section?
      redirect_to(
        instructor_focus_selector_path(
          program_id: params[:program_id],
          feature_type: 'individual assignment'
        )
      )
    end
  end

  def export
    respond_to do |format|
      format.csv do
        send_data @presenter.to_csv, filename: 'individual_assignments.csv'
      end
    end
  end

  def update
    assignment = Assignment.find_by!(
      assignable_id: params[:id], section_id: @section_id
    )
    assignment.update!(individually_assignable: params[:individually_assignable])

    # If individually_assignable is moving from `true` to `false`, clear the
    # existing individual assignments.
    if !params[:individually_assignable]
      # The updater
      #
      # 1. destroys all individual assignments for the given activity and
      #    section
      #
      # 2. creates individual assignments for each key in the hash associated
      #    with the activity ID, where each key represents a user
      #
      # Because I don't want to create new individual assignments, I map the
      # activity ID to an empty hash.
      #
      activity_users_map = { "activity_#{params[:id]}" => {} }

      IndividualAssignmentUpdater.new(
        activity_users_map,
        @section_id
      ).update
    end

    head :ok
  end

  def update_all
    IndividualAssignmentUpdater.new(params.to_unsafe_hash, @section_id).update

    flash[:notice] = 'Changes saved.'

    redirect_to instructor_individual_assignments_path(
      lesson_id: params[:lesson_id],
      only_individual: params[:only_individual],
      program_id: params[:program_id],
      week: params[:week]
    )
  end

  private def require_individual_assigning_to_be_enabled
    return if @course&.allow_individual_assign?

    flash[:error] = COURSE_DISABLED_MESSAGE
    redirect_to instructor_dashboard_path
  end

  # Load section from focus. If none, grab first section in course.
  private def assign_section_id
    @section_id = @sections.first.id
  end

  private def assign_menu_coords
    @menu_location = 'content'
  end

  private def assign_presenter
    @presenter = IndividualAssignmentsPresenter.new(@section_id, params)
  end
end
