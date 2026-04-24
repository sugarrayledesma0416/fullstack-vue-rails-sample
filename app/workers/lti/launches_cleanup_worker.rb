module Lti
  class LaunchesCleanupWorker
    include Sidekiq::Worker

    BATCH_SIZE = 100
    MAX_BATCH_COUNT = 1_000

    # Keep only 30 days of launch data
    def perform(date = 30.days.ago.to_date.to_s)
      batch_count = 0
      launches_to_destroy(date).in_batches(of: BATCH_SIZE) do |launch_batch|
        launch_batch.delete_all

        batch_count += 1
        break if batch_count >= MAX_BATCH_COUNT
        sleep 0.12
      end
    end

    private def launches_to_destroy(date)
      # uses AREL to generate date comparison SQL rather than string interpolation
      Lti::Launch.where(Lti::Launch.created_at_column.lteq(date))
    end
  end
end
