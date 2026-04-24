class SchoolDataDeleterWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options retry: 5, failures: :exhausted

  def perform(school_id)
    @school_id = school_id
    SchoolDataDeleter.new(school_id).delete_school_data
  end
end
