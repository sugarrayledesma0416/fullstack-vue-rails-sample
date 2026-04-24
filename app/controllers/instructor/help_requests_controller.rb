class Instructor::HelpRequestsController < RequireInstructorController

  include HasHelp
  before_action :contextual_help_url
  before_action :assign_menu_coords

  def index
    @page_title = 'Student Requests'
    @presenter = InstructorHelpRequestsPresenter.new(@sections, @students).populate
  end

  def assign_menu_coords
    @menu_location = 'communication'
  end
end
