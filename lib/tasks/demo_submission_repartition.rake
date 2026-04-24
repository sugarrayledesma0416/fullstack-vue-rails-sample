require_relative 'demo_submission_repartition.rb'

namespace :submission_api do
  desc 'Repartition demo student submissions from the specified year to a date in the current year ' \
       'and update the related attempts'

  task repartition_demo_submissions: :environment do |task|
    year = ENV.fetch('year', '')
    unless year.match?(/^\d{4}$/)
      puts'usage: rake year=<YYYY> dry_run=true|false'
      exit(1)
    end

    dry_run = ENV['dry_run'] != 'false'
    puts 'DRY RUN mode, no attempts or submissions will be updated!' if dry_run

    num_attempts_updated = 0
    failed_updates = 0

    repartitioner = DemoSubmissionRepartition.new(year: year, dry_run: dry_run)
    attempts = repartitioner.model_student_attempts
    if attempts.count.zero?
      puts 'No matching attempts found - nothing to do.'
      exit(1)
    end

    puts "Repartitioning #{attempts.count} demo submissions from #{year} " \
         'and updating related attempts.'
    attempts.each do |attempt|
      updated_attempt = repartitioner.update_attempt(attempt)
      if updated_attempt
        num_attempts_updated += 1
      else
        failed_updates += 1
      end
    end

    puts "Successfully repartitioned #{num_attempts_updated} submission(s) with partition key " +
         repartitioner.partition_key
    if failed_updates.positive?
      puts "Failed to update #{failed_updates} submission(s) and attempt(s)."
    end
  end
end
