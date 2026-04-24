module Portfolio
  class BulkGroupsResyncWorker
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
      program = course.program
      school = course.school

      sync_institute(school)
      bulk_groups_resync(course, school.reload.school_config, program)
    end
  end
end
