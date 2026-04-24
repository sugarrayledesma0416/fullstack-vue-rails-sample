class ProgramConfigVersionsController < ApplicationController
  before_action :require_user

  def index
    authorize! :view, ProgramConfigVersionsController
    @program = Program.find(params[:program_id])
    @program_config_versions = ProgramConfig.program_version_history(@program)
  end
end
