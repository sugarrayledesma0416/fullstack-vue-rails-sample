class SidekiqMonitorController < ApplicationController
  # This simple controller ensures (via ApplicationController) that after a user
  # has loggegd in with developer privileges, the correct session data has been created
  # for DeveloperConstraint to pass. DeveloperConstraint is a route constraint on the
  # Sidekiq::Web Rack application mounted to /sidekiq.

  before_action :require_user
  before_action :require_developer

  def sidekiq_redirect
    # This method is associated with the /sidekiq_monitor route in routes.rb.
    redirect_to '/sidekiq'
  end
end
