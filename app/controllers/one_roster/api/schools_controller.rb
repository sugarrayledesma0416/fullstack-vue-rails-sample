module OneRoster
  module Api
    class SchoolsController < ActionController::Base
      include HttpBasicAuthHelper

      skip_before_action :verify_authenticity_token
      before_action :http_basic_authenticate

      def update
        salesforce_id = params[:salesforce_id]
        require_school(salesforce_id)
        OneRoster::CourseSectionUpdaterWorker.perform_async(@school.id)
        # respond back immediately; this is a fire and forget
        # endpoint for the caller
        render json: { status: :ok }
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private def require_school(salesforce_id)
        @school = School.find_by(salesforce_id: salesforce_id)
        @school || (raise "School not found for salesforce_id: #{salesforce_id}")
      end
    end
  end
end
