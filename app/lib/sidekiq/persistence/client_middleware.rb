module Sidekiq
  module Persistence
    class ClientMiddleware
      include HealthCheck

      def call(worker, msg, queue, _redis_pool = nil)
        check_health

        # msg['at'] is only present if the task is scheduled for later
        scheduled_for = msg['at'].present? ? msg['at'].to_i : nil

        # When a scheduled job transitions to running,
        # it passes through this client middleware again and
        # we don't want to create another record

        ::ScheduledJob.find_or_create_by(jid: msg['jid']) do |job|
          job.worker_class = msg['class']
          job.args = msg['args'].to_json
          job.enqueued_at = msg['enqueued_at'].to_i
          job.scheduled_for = scheduled_for
        end

        yield
      end
    end
  end
end
