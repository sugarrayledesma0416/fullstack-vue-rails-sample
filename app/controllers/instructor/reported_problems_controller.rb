class Instructor::ReportedProblemsController < RequireInstructorController

  include HasHelp

  before_action :contextual_help_url
  before_action :assign_menu_coords

  def index
    @page_title = 'Student Technical Requests'
    @reported_problems = HelpRequest.reported_problems_by_section(@sections).include_students.include_location
  end

  def assign_menu_coords
    @menu_location = 'communication'
  end
end
