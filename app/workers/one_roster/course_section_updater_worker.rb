module OneRoster
  class CourseSectionUpdaterWorker
    include Sidekiq::Worker
    include WorkerInstrumentation
    include WorkerConflictManagement

    ORCSU_IN_PROGRESS_KEY = 'CourseSectionUpdaterWorker.%<school_id>d'.freeze

    def perform(school_id)
      logger_data_merge(school_id: school_id)
      cache_key = format(
          ORCSU_IN_PROGRESS_KEY,
          school_id: school_id
      )
      if conflict?([cache_key])
        logger_data_merge(error_key: school_id, course_section_updater_error: 'job is currently in process for this school')
      else
        in_progress(cache_key)
        # retrieve all LinkedSections for this school
        # for each update the course and section
        linked_course_external_ids = LinkedSection.where(school_id: school_id)
                                                  .pluck(:course_external_id)
                                                  .uniq
        linked_course_external_ids.each do |linked_course_external_id|
          course_section_updater = CourseSectionUpdater.new(school_id, linked_course_external_id)
          course_section_updater.update
          log_updater_error(school_id, course_section_updater) if course_section_updater.errors.present?
        end
      end
    ensure
      completed_progress(cache_key)
    end

    private def log_updater_error(school_id, course_section_updater)
      # log errors that came back from updating courses/sections
      course_section_updater.errors.each do |error|
        logger_data_merge(error_key: school_id, course_section_updater_error: error)
      end
    end
  end
end
