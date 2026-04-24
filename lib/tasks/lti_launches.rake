require_relative 'lti_launches_cleaner'

namespace :lti_launches do
  desc 'destroys all Lti launches older than 30 days'
  task destroy_old_launches: :environment do
    batch_size = 1000
    cleaner = LtiLaunchesCleaner.new(batch_size:)

    puts 'Delete Lti::Launch records older than 30 days'
    progress_bar = ProgressBar.create(
      title: 'Deleting old Lti launches',
      total: cleaner.num_batches,
      format: "%a %e Processed: %c/%C batches of #{batch_size} records (%P%%)"
    )

    cleaner.clean do
      progress_bar.increment
      # Sleep a bit to not hammer the database.
      sleep 0.1
    end
    progress_bar.finish
    puts 'done'
  end
end
