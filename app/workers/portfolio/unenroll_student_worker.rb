module Portfolio
  class UnenrollStudentWorker
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

    def perform(section_id, student_ids)
      logger_data_merge(section_id:, student_ids:)
      section = Section.find(section_id)
      school_config = section.school.school_config
      students = Student.find(student_ids)
      update_group_members(
        school_config, section.guid, [], students.pluck('username'), 'member'
      )
    end
  end
end
