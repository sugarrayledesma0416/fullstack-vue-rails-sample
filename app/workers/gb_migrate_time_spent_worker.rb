class GbMigrateTimeSpentWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  sidekiq_options retry: false

  def perform(score_action_ids)
    GradebookEngine::GradebookAPI.migrate_time_spent(score_action_ids)
  end
end
