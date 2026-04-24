class CourseLicenseCreatorWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  sidekiq_options queue: :medium_priority, retry: 10, failures: :exhausted

  # The current retry count is yielded. The return value of the block must be
  # an integer. It is used as the delay, in seconds.
  sidekiq_retry_in do |count|
    [8, 13, 21, 34, 55, 89][count]
  end

  # # in case the above is not enough time, maybe UA is down so the
  # course does not get created, we need to know that the course license failed
  # to be created in API and manual intervention is necessary to rectify this
  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(course_guid, course_package_ids)
    logger_data_merge(course_guid: course_guid, course_package_ids: course_package_ids)
    CourseLicenseCreator.new(course_guid, course_package_ids).create_license
  end

end
