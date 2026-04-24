class Gradebook::EmailController < RequireInstructorController
  
  include HasHelp
  before_action :contextual_help_url

  def list
    @return_to = vhl_return_to_sanitizer(params[:return_to])
  end    
end
