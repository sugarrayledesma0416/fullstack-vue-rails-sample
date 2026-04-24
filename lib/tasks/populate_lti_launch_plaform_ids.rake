namespace :lti do
  desc 'Populate the lti_platform_id attributes in the lti_launches table'
  task populate_lti_launches_lti_platform_ids: :environment do |task_name|
    dry_run = ENV['dry_run']&.downcase == 'true'

    if %w[true false].exclude?(ENV['dry_run']&.downcase)
      puts "usage: #{task_name} dry_run=true|false"
      exit 1
    end

    puts 'DRY RUN mode, no Lti launch will be updated!' if dry_run

    launches = Lti::Launch.where(lti_platform_id: nil)
    progress_bar = ProgressBar.create(
      title: 'Updating Lti launches',
      total: launches.count,
      format: '%a %e Processed: %c from %C'
    )

    num_launches_updated = 0
    launches.find_each(batch_size: 1000) do |launch|
      platform_id = launch.platform&.id
      if platform_id && !dry_run
        launch.update!(lti_platform_id: platform_id)
      end
      num_launches_updated += 1
      progress_bar.increment
    end

    progress_bar.finish
    puts "Updated #{num_launches_updated} Lti launches"
  end
end
