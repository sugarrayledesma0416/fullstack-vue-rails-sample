module Sidekiq
  module Persistence
    class ServerMiddleware
      include HealthCheck

      def call(_worker, msg, _queue, _redis_pool = nil)
        check_health

        job = ::ScheduledJob.find_by(jid: msg['jid'])
        job&.running!

        # capture job errors and ensure ScheduledJob record cleanup
        begin
          yield
        ensure
          job&.delete
        end
      end
    end
  end
end
