namespace :scheduled_jobs do
  desc "Requeue scheduled jobs"
  task :requeue => :environment do
    jobs = ScheduledJob.queued    
    if jobs.size == 0
      puts "There are no jobs to requeue."
    else
      worker_classes = jobs.map(&:worker_class).join(", ")
      puts "#{pluralize(jobs.size, 'job has', 'jobs have')} been requeued: #{worker_classes}"
      ScheduledJob.requeue!
    end
  end
end

def pluralize(count, singular, plural)
  "#{count} #{count == 1 ? singular : plural}"
end
