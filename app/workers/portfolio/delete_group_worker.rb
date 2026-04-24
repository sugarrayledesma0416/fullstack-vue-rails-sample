module Portfolio
  class DeleteGroupWorker
    include Sidekiq::Worker
    include Portfolio::SyncService
    include WorkerInstrumentation

    sidekiq_options queue: :medium_priority, retry: 3, failures: :exhausted

    sidekiq_retry_in do |count|
      [8, 13, 21, 34][count]
    end

    sidekiq_retries_exhausted do |msg|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    def perform(section_guid, school_id)
      logger_data_merge(section_guid:, school_id:)
      school_config = SchoolConfig.find_by(school_id:)
      delete_group(section_guid, school_config)
    end
  end
end
