class Cartridge::Instructor::GradingController < ApplicationController
  helper MaestroActivityEngine::ActivitiesHelper
  include CartridgeViewable

  before_action :require_user
  before_action :require_instructor
  before_action :assign_section

  def show
    activity = Activity.find(params[:id])
    program = activity.program
    attempts = Attempt.by_section(@section)
                      .by_activities(activity)
                      .submitted_or_completed
    GradingSet.create_or_update(
      current_user.id,
      {
        activity_id: activity.id,
        program_id: program.id,
        show_hide_comments: false
      },
      attempts.map(&:user_id)
    )
    session[:grading_done_return_to] = cartridge_section_activity_path(params[:section_id], params[:id])
    # if there is no assignment, then set grading task accordingly as UNASSIGNED_ACTIVITIES
    assignment = Assignment.where(section: @section, assignable: activity)
    task_type = assignment.exists? ? GradingTask::NEEDS_GRADING : GradingTask::UNASSIGNED_ACTIVITIES
    redirect_to instructor_grading_styles_path(
      program_id: program.id,
      activity_id: activity.id,
      task_type: task_type
    )
  end

  private def assign_section
    @section = Section.find(params[:section_id])
  end
end
