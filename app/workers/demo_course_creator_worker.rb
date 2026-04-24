class DemoCourseCreatorWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  sidekiq_options retry: 10, dead: false

  sidekiq_retry_in do |count, error|
    # For model demo data errors, expire in about 5 minutes.
    if error.message =~ /no model demo \w+ was found/
      30  # retry in 30 seconds
    end

    # Any other error will use the default backoff formula
    # which should expire the job in about 4 hours if
    # nothing is done to resolve the error.
  end

  def perform(params)
    # add params to logging data
    logger_data_merge(job_params: params)

    demo_course_creator = DemoCourseBuild::Creator.new(params)

    unless demo_course_creator.create_course
      raise demo_course_creator.errors.full_messages.join('|')
    end
  end
end
