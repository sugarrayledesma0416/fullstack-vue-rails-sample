class GbDataSyncWorker
  include Sidekiq::Worker
  include WorkerInstrumentation
  include Etl::GradebookImport

  sidekiq_options queue: :highest_priority, retry: 2, failures: :exhausted

  # The current retry count is yielded. The return value of the block must be
  # an integer. It is used as the delay, in seconds.
  sidekiq_retry_in do |count|
    [1, 2, 3, 5, 8, 13, 21, 34, 55, 89][count]
  end

  # in case the above is not enough time, maybe SQS is not available
  # the migration of the sections for this course failed
  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(params)
    logger_data_merge(gb_updater_params: params)
    migrator_model_name = params['model_name'].to_s.delete(':')
    migrator_class = "Gb#{migrator_model_name}Migrator".classify
    migrator_class.constantize.new(params).update_object
  rescue => e
    # Ensure failures don't get hidden when running in test mode.
    if Rails.env.test? && defined?(SHOW_SIDEKIQ_ERRORS) && SHOW_SIDEKIQ_ERRORS
      Sidekiq.logger.error(
        "\n\n\n#{migrator_class}: #{e.message}\n#{app_lines(e.backtrace)}"
      )
    end
    raise e
  end

  private def app_lines(backtrace)
    backtrace.select { |line| line.start_with?(Rails.root.to_s) }.join("\n")
  end
end
