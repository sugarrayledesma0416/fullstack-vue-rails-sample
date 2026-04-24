class GbObjectMigratorWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  sidekiq_options retry: 2, failures: :exhausted

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

  def perform(class_name, params)
    logger_data_merge(migration_params: params)
    "Gb#{class_name}Migrator".classify.constantize.new(params).migrate_objects
  end

end
