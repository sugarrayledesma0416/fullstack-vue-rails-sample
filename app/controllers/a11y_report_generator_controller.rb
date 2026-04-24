class A11yReportGeneratorController < ApplicationController
  before_action :require_user
  before_action :validate_role

  def index
    @programs = Program.where(is_archived: false).order(:title)
  end

  def report
    @program = Program.find(params[:program_id])
    @reporter = A11yReportGenerator.new(@program.id)
  end

  def generate_new_report
    @program = Program.find(params[:program_id])
    A11yReportGeneratorWorker.perform_async(@program.id, params[:include_details])
  end

  private def validate_role
    authorize! :report, A11yReportGeneratorController
  end
end
