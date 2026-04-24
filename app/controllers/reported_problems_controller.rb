class ReportedProblemsController < ApplicationController

  before_action :require_user
  before_action :require_program_access

  def index
    # specifying nil section because reported_problems do not filter by section
    @presenter = HelpRequestsPresenter.new(section = nil, current_user, params[:status], :reported_problems).populate
    @page_title = 'Technical Support Requests'
    @return_path = best_default_path
  end
end
