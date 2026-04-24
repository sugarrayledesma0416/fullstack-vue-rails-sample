class RosterController < RequireInstructorController
  include DateTimeHelper
  include SectionSelector

  layout 'application_v3'

  before_action :require_section_access, unless: :current_user_is_institution_admin?

  def show
    @menu_location = 'grades'
    @page_title = 'Roster'
    @grace_periods = GracePeriodAllocation.new(current_focus.course_school_id)
    @presenter = RosterPresenter.new(section_ids, current_program)
    @presenter.update_sufficient_access

    @sections = current_focus.sections
    assign_session_selector_attrs

    check_access(@presenter.students)

    render :roster
  end

  # If we're viewing by section, return the single section's id. If viewing by
  # course, look up the ids of all sections in the course.
  private def section_ids
    params[:section_id] || Course.find(params[:course_id]).sections.map(&:id)
  end
end
