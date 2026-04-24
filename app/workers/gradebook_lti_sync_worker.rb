class GradebookLtiSyncWorker
  include Sidekiq::Worker
  include WorkerInstrumentation
  include WorkerCheck

  def perform
    return unless no_prior_process_running?

    GradebookEngine::Lti::MultiContextLinkSyncer.new.sync_all
  end
end
