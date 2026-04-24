class Instructor::ProntoController < RequireInstructorController

  include HasHelp
  before_action :ensure_pronto_availability
  before_action :contextual_help_url

  def show
    @page_title = 'Blackboard IM (Formerly Wimba Pronto)'
  end 

  def ensure_pronto_availability
    program_settings = ProgramSettings.new(current_program)
    if program_settings.nil? || !program_settings.has_pronto?
      flash[:notice] = "This Supersite does not offer Pronto integration."
      redirect_to instructor_dashboard_path(current_program)
    end
  end
end
