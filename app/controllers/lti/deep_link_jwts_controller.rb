module Lti
  class DeepLinkJwtsController < ApplicationController
    def create
      jwt = if params[:view] == 'homepage'
              home_page_jwt
            elsif params[:view] == 'dashboard'
              dashboard_jwt
            else
              activity_jwt
            end
      render json: jwt.to_h.to_json
    end

    private def home_page_jwt
      HomePageDeepLinkJwt.new(params[:launch_guid])
    end

    private def dashboard_jwt
      DashboardDeepLinkJwt.new(params[:program_id], params[:launch_guid])
    end

    private def activity_jwt
      ActivityDeepLinkJwt.new(params[:activity_id], params[:launch_guid])
    end
  end
end
