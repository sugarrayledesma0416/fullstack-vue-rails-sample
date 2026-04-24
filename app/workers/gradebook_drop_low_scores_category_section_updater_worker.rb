class GradebookDropLowScoresCategorySectionUpdaterWorker
  include Sidekiq::Worker
  include WorkerInstrumentation
  include WorkerConflictManagement

  DLSCS_IN_PROGRESS_KEY = 'GradebookDropLowScoresSchedulerWorker.%<school_id>d.%<section_id>d.%<category_id>d'.freeze
  DLSCS_IN_PROGRESS_WILDCARD_KEY = 'GradebookDropLowScoresCategorySectionUpdaterWorker.%s.*'.freeze
  CONFLICT_KEYS = [GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY].freeze

  sidekiq_options queue: :medium_priority, retry: false

  def perform(category_id, section_id, max_score_action_id, queue_time, school_id)
    logger_data_merge(category_id: category_id,
                      section_id: section_id,
                      max_score_action_id: max_score_action_id,
                      queue_time: queue_time,
                      school_id: school_id)
    raise SchoolMergeJobConflictError if conflict?(CONFLICT_KEYS)

    # there will be multiple jobs of the same type so as not to overwrite the
    # in_progress flag add section and category.
    # lookup will wildcard after school_id
    cache_key = format(
      DLSCS_IN_PROGRESS_KEY,
      category_id: category_id,
      school_id: school_id,
      section_id: section_id
    )
    in_progress(cache_key)
    GradebookEngine::DropLowScoresCategorySectionLockingUpdater.new(
      category_id,
      section_id,
      max_score_action_id,
      queue_time
    ).find_job_and_maybe_update
  ensure
    completed_progress(cache_key)
  end
end
