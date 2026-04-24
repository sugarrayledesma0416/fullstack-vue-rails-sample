class InstitutionAdminGradebookAssignmentSyncWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(section_id)
    Assignment.where(section_id: section_id)
              .each(&:notify_update)
  end
end
