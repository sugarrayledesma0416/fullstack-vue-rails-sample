class GbSchoolMergeWorker
  include Sidekiq::Worker
  include WorkerInstrumentation
  include WorkerConflictManagement

  SCHOOL_UPDATE_IN_PROGRESS_KEY = 'GbSchoolMergeWorker'.freeze
  CONFLICT_KEYS = [StudentWorkTransferWorker::SWT_IN_PROGRESS_KEY,
                   GradebookDropLowScoresSchedulerWorker::DLS_IN_PROGRESS_KEY].freeze

  sidekiq_options queue: :highest_priority, retry: 10, failures: :exhausted

  # The current retry count is yielded. The return value of the block must be
  # an integer. It is used as the delay, in seconds.
  sidekiq_retry_in do |count|
    [1, 2, 3, 5, 8, 13, 21, 34, 55, 89][count]
  end

  # in case the above is not enough time,
  # updating the school failed
  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  # schools are being merged so all objects in the loser school
  # need to have school_id updated to that of the winner school
  def perform(params)
    logger_data_merge(gb_school_merge_params: params)
    # check if StudentWorkTransfer or Drop Scores jobs
    # are running. if so, fail this job which will
    # force a Sidekiq retry.
    raise SchoolMergeJobConflictError if conflict?(conflict_keys(params['old_school_id']))
    # if good to go set a flag to indicate this job is running.
    # do the merge and then remove the flag
    in_progress(SCHOOL_UPDATE_IN_PROGRESS_KEY)
    GradebookEngine::GradebookAPI.change_schools(**params.symbolize_keys)
  rescue => e
    # Ensure failures don't get hidden when running in test mode.
    if Rails.env.test? && defined?(SHOW_SIDEKIQ_ERRORS) && SHOW_SIDEKIQ_ERRORS
      Sidekiq.logger.error(
        "\n\n\n GbSchoolMergeWorker: #{e.message}\n#{app_lines(e.backtrace)}"
      )
    end
    raise e
  ensure
    completed_progress(SCHOOL_UPDATE_IN_PROGRESS_KEY)
  end

  private def app_lines(backtrace)
    backtrace.select { |line| line.start_with?(Rails.root.to_s) }.join("\n")
  end

  private def conflict_keys(old_school_id)
    [StudentWorkTransferWorker::SWT_IN_PROGRESS_KEY,
     GradebookDropLowScoresSchedulerWorker::DLS_IN_PROGRESS_KEY,
     GradebookDropLowScoresCategorySectionUpdaterWorker::DLSCS_IN_PROGRESS_WILDCARD_KEY %  old_school_id]
  end
end
