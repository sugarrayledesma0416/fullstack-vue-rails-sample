class CourseLicenseCreator
   attr_reader :course_guid, :course_package_ids

  def initialize(course_guid, course_package_ids)
    @course_guid = course_guid
    @course_package_ids = course_package_ids
  end

  def create_license
    begin
      Maestro::CourseLicense.create(@course_guid, @course_package_ids)
    rescue StandardError => e
      VHLMonitor.notify(e)
      # raising this exception will cause Sidekiq to retry the job
      # which is desired behavior. Expected cause of error is that
      # the course has not been added to the UA database,
      # and API cannot create the license until it has been.
      raise e
    end
  end

end
