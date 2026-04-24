
class CompositionDraftsCleanerWorker
  include Sidekiq::Worker

  def perform
    CompositionAttachment.expired_drafts.map(&:destroy)
  end

end
