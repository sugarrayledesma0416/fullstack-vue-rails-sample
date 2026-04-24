Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

if Rails.env.live?
  remove_task('db:drop')
  remove_task('db:reset')
  remove_task('db:seed')
  remove_task('db:migrate:reset')
end

namespace :db do
  desc 'Migrate the m3 and gradebook databases'
  task :deploy => :environment do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    Rake::Task['db:migrate'].invoke
    Rake::Task['gradebook:db:migrate'].invoke
  end
end
