class GradebookLtiOnDemandSyncWorker
  include Sidekiq::Worker
  include WorkerInstrumentation
  include WorkerCheck
  sidekiq_options retry: false

  def perform(context_link_id)
    context_link = GradebookEngine::Lti::ContextLink.find(context_link_id)
    section = context_link.section

    logger_data_merge(
      course_id: section.course_id,
      lms_context_id: context_link.context_id,
      params: { context_link_id: },
      school_id: section.school_id,
      section_id: section.id,
      section_name: section.name,
      sync_level: context_link.sync_level
    )

    if identical_process_running?(context_link_id)
      # identical job class and same args. Abort this job.
      logger_data_merge(errors: ['Conflict with identical sync job'])
    else
      syncer = GradebookEngine::Lti::ContextLinkSyncer.new(
        context_link:,
        cleanup: true
      )
      syncer.sync
      log_data(syncer)
    end
  end

  # rubocop:disable Style/GuardClause
  private def log_data(syncer)
    if syncer.error_collector.has_errors?
      logger_data_merge(
        errors: syncer.error_collector.errors
      )
    end

    if syncer.error_collector.has_warnings?
      logger_data_merge(
        warnings: syncer.error_collector.warnings
      )
    end
  end
  # rubocop:enable Style/GuardClause
end
