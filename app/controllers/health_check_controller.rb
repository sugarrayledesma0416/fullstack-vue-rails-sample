class HealthCheckController < ActionController::Base
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include HttpBasicAuthHelper

  before_action :http_basic_authenticate, only: :health_check

  # TODO: Deprecated; used for F5 load balancers.
  # Load balancers may use this endpoint to determine if an M3 server
  # is fit to be added to the load balancing pool.
  def health_check
    # Run a simple query to make sure that the database connection
    # works.
    Program.first

    # Test Gradebook connection, too.
    GradebookEngine::Lesson.first

    render inline: "Get me my swimmies, I'm going in the pool!"
  end

  def elb_health_check
    if basic_auth_valid?('elb_token', params[:token])
      health_check
    else
      head :forbidden
    end
  end
end
