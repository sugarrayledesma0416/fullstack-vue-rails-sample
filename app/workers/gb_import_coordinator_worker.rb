class GbImportCoordinatorWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  sidekiq_options retry: false

  def perform(num_workers, num_messages)
    logger_data_merge(num_workers: num_workers, num_messages: num_messages)
    num_workers.times do
      GbImportWorker.perform_async(num_messages)
    end
  end

end
