class StandardsUpdateWorker
  include UpdateStandards
  include Sidekiq::Worker
  include WorkerInstrumentation
  include WorkerConflictManagement

  STDS_UPDATE_IN_PROGRESS_KEY = 'StandardsUpdateWorker'.freeze

  sidekiq_options queue: :default, retry: 2, failures: :exhausted

  # The current retry count is yielded. The return value of the block must be
  # an integer. It is used as the delay, in seconds.
  sidekiq_retry_in do |count|
    [1, 2, 3, 5, 8, 13, 21, 34, 55, 89][count]
  end

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  #  - trigger AcademicBenchmarks API to retrieve updated Standards
  # and new StandardSets
  #  - set searchable flag to false for any Standard that has no
  #    number AND no label
  #  - upload new and updates Standards to OpenSearch standrds index
  def perform
    # there could already be an update job running (CMS user hits the button more than once);
    # if so do not run this job, the other one will complete;
    # no need for a retry
    if !conflict?([STDS_UPDATE_IN_PROGRESS_KEY])
      # all clear so run the job
      in_progress(STDS_UPDATE_IN_PROGRESS_KEY)
      # pull all standards from AB and set searchable flag
      error_response = update_all
      Sidekiq.logger.error "Pulling standards from AB had failures: #{error_response.join(',')}" unless error_response.empty?
      # update Standards in OS; log error
      error_response = update_search
      Sidekiq.logger.error "Updating standards in OpenSearch failed with error: #{error_response.join(',')}" unless error_response.empty?
    else
      Sidekiq.logger.warn "StandardsUpdateWorker in progress; do not start another one"
    end
  ensure
    completed_progress(STDS_UPDATE_IN_PROGRESS_KEY)
  end
end
