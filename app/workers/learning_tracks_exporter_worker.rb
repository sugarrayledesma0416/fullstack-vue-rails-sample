class LearningTracksExporterWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options retry: false

  def perform(program_id)
    program = Program.find(program_id)
    LearningTrack::LearningTrackFileCreator.create(program)
  end
end
