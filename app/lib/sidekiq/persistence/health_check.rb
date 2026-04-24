module Sidekiq
  module Persistence
    module HealthCheck

      def check_health
        begin
          ::Rails.logger.debug("HealthCheck")
          ::ScheduledJob.first  # health check
        rescue StandardError => e
          ::Rails.logger.debug("RESCUE: #{e.message}")
          if e.message =~ /Mysql2::Error: MySQL server has gone away/
            ActiveRecord::Base.connection.disconnect!
            ActiveRecord::Base.establish_connection
            ::Rails.logger.debug("RECONNECT")
          else
            raise e
          end
        end
      end

    end
  end
end
