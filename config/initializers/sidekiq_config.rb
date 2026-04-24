require 'sidekiq'
require 'sidekiq-status'
require 'sidekiq/throttled'

# configure the redis server for Sidekiq
raw_yaml = ERB.new(Rails.root.join('config/redis.yml').read).result
redis_config = (YAML.safe_load(raw_yaml, aliases: true)[Rails.env] || {}).symbolize_keys

host = redis_config[:host]
port = redis_config[:port]
password = redis_config[:password]

redis_url = if password.present?
              "redis://:#{CGI.escape(password)}@#{host}:#{port}"
            else
              "redis://#{host}:#{port}"
            end

VHLMonitor::LogstashNotifier.initialize(Rails.configuration.maestro_monitoring)

# This wrapper takes care of deprecation warnings resulting from the zeitwerk loader
Rails.application.reloader.to_prepare do
  # https://github.com/mperham/sidekiq/wiki/Pro-Reliability-Client
  Sidekiq::Client.reliable_push! unless Rails.env.test?

  Sidekiq.configure_client do |config|
    config.redis = { url: redis_url }
    config.error_handlers << proc { |ex, context| VHLMonitor.notify(ex, context) }
    config.error_handlers << proc do |ex, context|
      VHLMonitor::LogstashNotifier.notify(
        ex,
        context.merge(
          'sidekiq' => 'client',
          'object_id' => ex.object_id.to_s
        )
      )
    end

    config.client_middleware do |chain|
      chain.add Sidekiq::Status::ClientMiddleware
      chain.add Sidekiq::Persistence::ClientMiddleware
    end

    config.strict_args!
  end

  Sidekiq.configure_server do |config|
    config.logger.level = Rails.logger.level

    config.redis = { url: redis_url }

    config.error_handlers << proc { |ex, context| VHLMonitor.notify(ex, context) }
    config.error_handlers << proc do |ex, context|
      VHLMonitor::LogstashNotifier.notify(
        ex,
        context.merge(
          'sidekiq' => 'server',
          'object_id' => ex.object_id.to_s
        )
      )
    end

    # enable Reliability features
    # https://github.com/mperham/sidekiq/wiki/Reliability
    config.super_fetch!
    config.reliable_scheduler!

    # Ensure there are as many RecoveryLog pool members as there are sidekiq
    # threads.
    Dangerfield.configuration.recovery_log_pool_size = Sidekiq.options[:concurrency]

    # Log job info as JSON for live only.
    config.log_formatter = Sidekiq::Logger::Formatters::JSON.new if Rails.env.live?

    config.server_middleware do |chain|
      chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes
      chain.add Sidekiq::Persistence::ServerMiddleware

      # logstash hooks
      chain.add Sidekiq::Middleware::Server::Logstash, client: STATS_PROXY
    end

    config.client_middleware do |chain|
      chain.add Sidekiq::Status::ClientMiddleware
      chain.add Sidekiq::Persistence::ClientMiddleware
    end

    config.strict_args!
  end

  if Sidekiq.server? && !Rails.env.test? # are we a Sidekiq server?
    # Set up AI tracing shutdown hook to gracefully close trace providers
    # when Sidekiq server terminates
    at_exit do
      tracer_provider = OpenTelemetry.tracer_provider

      # Only attempt shutdown if we have an SDK TracerProvider (not the no-op default)
      if tracer_provider.is_a?(OpenTelemetry::SDK::Trace::TracerProvider)
        Sidekiq.logger.info('Shutting down AI tracing during Sidekiq server termination')
        tracer_provider.shutdown(timeout: 30)
        Sidekiq.logger.info('AI tracing shutdown completed successfully')
      else
        Sidekiq.logger.debug('No AI tracing to shutdown (using default no-op TracerProvider)')
      end
    rescue StandardError => e
      Sidekiq.logger.error("Error during AI tracing shutdown: #{e.message}")
      Sidekiq.logger.error("Shutdown error backtrace: #{e.backtrace.join("\n")}")
    end

    # set up your recurring jobs in this yaml file
    schedule_file = 'config/job_schedule.yml'

    if File.exist?(schedule_file)
      raw_yaml = File.read(schedule_file)
      Sidekiq::Cron::Job.load_from_hash(YAML.safe_load(raw_yaml, aliases: true))

      # On qa servers, we want to run drop low scores and the lti gradebook
      # syncer more frequently than the configured schedule in
      # config/job_schedule.yml
      # By using the same names, the yml file values are overriden.
      if Rails.env.qa?
        Sidekiq::Cron::Job.create(
          name: 'drop_low_scores',
          cron: '*/5 * * * *',
          queue: 'medium_priority',
          class: 'GradebookDropLowScoresSchedulerWorker'
        )
        Sidekiq::Cron::Job.create(
          name: 'lti_gradebook_syncer',
          cron: '*/2 * * * *',
          queue: 'default',
          class: 'GradebookLtiSyncWorker'
        )
      end
    end
  end

  # This should be at the end of this file to avoid load order issues.
  # https://github.com/sensortower/sidekiq-throttled#usage
  Sidekiq::Throttled.setup!
end
