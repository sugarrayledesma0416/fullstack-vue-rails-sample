namespace :parallel do
  namespace :specs do
    desc "Run core spec tests"
    task :core, [:procs] => :environment do |cmd_name, args|

      if args[:procs].nil?
        puts "Usage: rake parallel:specs:core[#_of_processors] [params='other rspec params']"
        puts "       params='other rspec params' can be used to pass other params like --profile"
        exit
      end

      run_spec_task('core', args[:procs])
    end

  end

  def run_spec_task(task_name = 'core', procs)
    ENV['SPEC_OPTS'] = "--tag #{task_name} #{ENV['params']}"
    Rake::Task['parallel:spec'].invoke(procs || 1)
  end
end
