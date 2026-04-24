module Portfolio
  class CreateGroupWorker
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

    def perform(section_id, instructor_ids)
      logger_data_merge(section_id:, instructor_ids:)
      section = Section.find(section_id)
      instructors = User.find(instructor_ids)
      program = section.program
      school = section.school

      sync_institute(school)
      create_group(section, instructors, program)
    end
  end
end
