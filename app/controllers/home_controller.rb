class HomeController < ApplicationController

  include HasHelp
  before_action :contextual_help_url, except: :ua_home
  skip_before_action :set_time_zone, only: :ua_home

  def front
    redirect_to "#{ defined?(UA_URL) ? UA_URL : 'https://www.vhlcentral.com' }/home"
  end

  def ua_home
    redirect_to "#{ defined?(UA_URL) ? UA_URL : 'https://www.vhlcentral.com' }/home"
  end
end

