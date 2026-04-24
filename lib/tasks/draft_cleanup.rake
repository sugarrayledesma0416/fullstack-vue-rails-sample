namespace :drafts do
  namespace :cleanup do

    desc "queues an draft cleaner with sidekiq"
    task :enqueue => :environment do
      cleaner = CompositionDraftsCleanerWorker.perform_async
    end
  end
end
