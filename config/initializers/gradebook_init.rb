# set up M3/gradebook connections
GradebookEngine::Config.configure do |config|
  config.auth_controller = '::RequireInstructorController'
  config.student_auth_controller = '::ApplicationController'
  config.reset_work_callback = lambda do |activity_id, user_id, section_id|
    ::Gradebook::ResetStudentWork.new(activity_id, user_id, section_id).process
  end
  config.lti_on_demand_sync_worker = '::GradebookLtiOnDemandSyncWorker'
  config.cache_manager = '::CacheManager'
  config.unit_image_finder = '::UnitImageFinder'
end
