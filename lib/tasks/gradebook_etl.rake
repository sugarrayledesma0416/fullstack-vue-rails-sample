namespace :gradebook_v2 do
  desc 'do ETL for new gradebook'
  task :etl => :environment do |task|
    unless ENV['COURSE_IDS']
      puts "USAGE: rake #{task} COURSE_IDS=<comma-separated list of course IDs> [KEEP_DATA=true]"
      exit
    end
    # we are leaving out score_action to reduce complexity
    # and because we don't think it's needed.
    models = ['course', 'section', 'category', 'section_user', 'user',
              'assignment', 'activity', 'strand', 'lesson']

    models.each do |model|
      gb_model = "GradebookEngine::#{model.camelize}".constantize
      puts "#{gb_model}\n" + ('-' * 40)
      gb_model.establish_connection(:"gradebook_#{Rails.env}")

      unless ENV['KEEP_DATA'] == 'true'
        puts "Clearing data"
        gb_model.delete_all
      end

      puts "Transforming data\n\n"
      filename = "#{model}.etl"
      script_content = IO.read("etl/#{filename}")
      job_definition = Kiba.parse(script_content, filename)
      Kiba.run(job_definition)
    end
  end
end
