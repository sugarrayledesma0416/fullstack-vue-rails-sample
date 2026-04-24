class GbMigrateSectionCurrentScoreActionsWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  sidekiq_options retry: false

  def perform(section_id)
    logger_data_merge(section_id: section_id)

    GradebookEngine::GradebookAPI.migrate_section_current_score_actions(section_id: section_id)
  end
end
