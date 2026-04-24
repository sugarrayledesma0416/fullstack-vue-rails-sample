class GradebookImportWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  sidekiq_options retry: false

  def perform(num_messages)
    logger_data_merge(num_messages: num_messages)
    Etl::GradebookImport.run(num_messages)
  end

end
