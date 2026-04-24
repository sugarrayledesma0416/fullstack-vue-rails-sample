class BulkResourcesCreatorWorker
  include BulkUploadIrs
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options retry: false

  def perform(params)
    program = Program.find_by(id: params['program_id'])
    tracker = setup_tracker(program.id)
    tracker.job_created!
    creator = BulkResourcesUploader::BulkResourcesCreator.new(program, tracker)
    creator.bulk_creation
  end
end
