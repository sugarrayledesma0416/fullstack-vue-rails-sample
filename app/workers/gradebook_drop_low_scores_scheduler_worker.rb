class GradebookDropLowScoresSchedulerWorker
  include Sidekiq::Worker
  include WorkerCheck
  include WorkerConflictManagement

  DLS_IN_PROGRESS_KEY = 'GradebookDropLowScoresSchedulerWorker'.freeze
  CONFLICT_KEYS = [GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY].freeze

  sidekiq_options queue: :medium_priority, retry: false

  def perform
    # ensure there is no conflict with SchoolMerge
    raise SchoolMergeJobConflictError if conflict?(CONFLICT_KEYS)
    if no_prior_process_running?
      # indicate that this job is running
      # so SchoolMerge knows not to run
      in_progress(DLS_IN_PROGRESS_KEY)
      GradebookEngine::DropLowScoresScheduler.new.enqueue_jobs
    end
  ensure
    # clear the in-progress flag no matter what
    # happened in the DropLowScores process
    completed_progress(DLS_IN_PROGRESS_KEY)
  end
end
