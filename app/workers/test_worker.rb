class TestWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  sidekiq_options retry: false

  def perform(id, name)
    logger_data_merge(id: id, name: name)
    [id, name]
    logger_data_merge(post_data: "work complete")
  end
end
