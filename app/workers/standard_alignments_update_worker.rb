class StandardAlignmentsUpdateWorker
  include UpdateStandardAlignments
  include Sidekiq::Worker
  include WorkerInstrumentation
  include WorkerCheck

  sidekiq_options queue: :default, retry: 2, failures: :exhausted

  # The current retry count is yielded. The return value of the block must be
  # an integer. It is used as the delay, in seconds.
  sidekiq_retry_in do |count|
    [1, 2, 3, 5, 8, 13, 21, 34, 55, 89][count]
  end

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    Rails.logger.warn "[StandardAlignmentsUpdateWorker] sidekiq_retries_exhausted - Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  #  - trigger AcademicBenchmarks API to retrieve updated StandardAlignments
  #    for StandardAssets in the specified program;
  #    then uploads them to OpenSearch
  def perform(params)
    program_id = params['program_id']
    logger_data_merge(
      program_id:,
      import_type: params['import_type'],
      params:
    )
    Rails.logger.info "[StandardAlignmentsUpdateWorker] perform - Received request to update standard alignments for program_id=#{program_id}"

    # no_prior_process_running? ensures no other job of this class is running.
    unless no_prior_process_running?
      logger_data_merge(errors: ['Another StandardAlignmentsUpdateWorker is running'])
      Sidekiq.logger.warn "StandardAlignmentsUpdateWorker for program #{program_id} in progress; do not start another one"
      Rails.logger.info "[StandardAlignmentsUpdateWorker] conflict - another job running for program_id=#{program_id}"
      return
    end

    Rails.logger.info "[StandardAlignmentsUpdateWorker] perform - Starting StandardAlignmentsUpdateWorker for program_id=#{program_id}"

    # Pull all update alignments from AB for the specified program; then update OpenSearch
    error_response = update_alignments(params)

    unless error_response.empty?
      logger_data_merge(errors: error_response)
      Rails.logger.error "[StandardAlignmentsUpdateWorker] perform - Pulling alignments from AB for program #{program_id} had failures: #{error_response.join(',')}"
      Sidekiq.logger.error "Pulling alignments from AB for program #{program_id} had failures: #{error_response.join(',')}"
    else
      Rails.logger.info "[StandardAlignmentsUpdateWorker] perform - Successfully updated alignments for program_id=#{program_id}"
    end
  ensure
    Rails.logger.info "[StandardAlignmentsUpdateWorker] perform - Completed StandardAlignmentsUpdateWorker for program_id=#{params['program_id']}"
  end
end
