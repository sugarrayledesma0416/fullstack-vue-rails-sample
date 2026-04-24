module WorkTransfer
  class PreviousSectionTransferWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    sidekiq_options retry: false, queue: :high_priority

    def perform(student, section_from, section_to)
      PreviousSectionTransfer.new(student, section_from, section_to).process
    end
  end
end
