module Portfolio
  class UpdateBulkGroupsWorker
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

    def perform(course_id)
      logger_data_merge(course_id:)
      course = Course.find(course_id)
      sections = course.sections
      school_config = course.school.school_config
      bulk_update_groups_details(school_config, sections, course)
    end
  end
end
