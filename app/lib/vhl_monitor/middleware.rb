require_relative '../vhl_monitor'

module VHLMonitor
  class Middleware
    def initialize(application)
      @app = application
      VHLMonitor::LogstashNotifier.initialize(Rails.configuration.maestro_monitoring)
    end

    def call(env)
      begin
        response = @app.call(env)

      # We have to go as broad as possible here.
      # Also Rollbar does the same and we want to catch all what Rollbar is able to catch
      # rubocop:disable Lint/RescueException
      rescue Exception => e
        VHLMonitor::LogstashNotifier.notify(e)

        raise e
      end
      # rubocop:enable Lint/RescueException
      response
    end
  end
end
