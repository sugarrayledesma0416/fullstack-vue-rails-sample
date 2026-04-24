namespace :gradebook_v2 do
  # Migrate a batch of Courses along with related Sections, Categories,
  # Enrollments, Assignments, Scores and Users.
  desc 'do Course migration ETL directly for new gradebook'
  task :migrate_course_etl => :environment do |task|
    unless ENV['START_ID']
      puts "USAGE: rake #{task} START_ID=<starting M3 id for course records> " \
           'END_ID=<ending M3 id for course records> [CLOSED_ONLY=<if true ' \
           'process closed courses only, if false, process only non-closed ' \
           'courses, defaults to false, has no effect if end date is not ' \
           'specified] [END_DATE=<format YYYY-MM-DD>] ' \
           '[ACTION=<import|add_update|delete, default to import>]'
      exit
    end

    puts "Migrating Courses and related data to SQS via ETL for env #{Rails.env}\n\n"
    closed_only = ENV['CLOSED_ONLY'].to_s.downcase == 'true'
    # action will default to 'import' unless specified
    action = ENV['ACTION'] ? ENV['ACTION'] : 'import'
    puts "ACTION #{action}"
    params = {
      action: action,
      closed_only: closed_only,
      end_date: ENV['END_DATE'],
      end_id: ENV['END_ID'],
      start_id: ENV['START_ID']
    }
    Kiba.run(Etl::CourseEtl.setup(params))
  end

  desc 'do migration of Courses via sidekiq jobs for new gradebook'
  task :migrate_course_sidekiq => :environment do |task|
    unless ENV['START_ID'] && ENV['END_ID'] && ENV['END_DATE'] && ENV['CLOSED_ONLY']
      puts "USAGE: rake #{task} START_ID=<starting M3 id for course records> " \
           'END_ID=<ending M3 id for course records> CLOSED_ONLY=<if true ' \
           'process closed courses only> END_DATE=<format YYYY-MM-DD> ' \
           '[ACTION=<import|add_update|delete, default: import] ' \
           'To migrate closed or open courses within a certain range of ids, you will need to specify these options: ' \
           'START_ID END_ID CLOSED_ONLY END_DATE '
      exit
    end

    puts "Migrating Courses and related data to SQS via sidekiq for env #{Rails.env}\n\n"
    # action will default to 'import' unless specified
    action = ENV['ACTION'] ? ENV['ACTION'] : 'import'
    puts "ACTION #{action}"
    closed_only = ENV['CLOSED_ONLY'].to_s.downcase == 'true'
    params = {
      action: action,
      closed_only: closed_only,
      end_date: ENV['END_DATE'],
      end_id: ENV['END_ID'],
      start_id: ENV['START_ID']
    }
    GbObjectMigratorWorker.perform_async('Course', params)
  end


  desc 'do migration of Courses for specified schools via sidekiq jobs for new gradebook'
  task :migrate_course_schools_sidekiq => :environment do |task|
    unless ENV['END_DATE'] && ENV['CLOSED_ONLY'] && ENV['SCHOOL_FILE']
      puts "USAGE: rake #{task}  CLOSED_ONLY=<if true process closed courses only> " \
           'END_DATE=<format YYYY-MM-DD> ' \
           'SCHOOL_FILE=<file of M3 school ids> ' \
           '[ACTION=<import|add_update|delete, default: import] ' \
           'If you are migrating closed or open courses for specified schools you will need to specify these options: ' \
           'CLOSED_ONLY END_DATE SCHOOL_FILE'
      exit
    end

    puts "Migrating Courses and related data for specified schools using SQS and Sidekiq for env #{Rails.env}\n\n"
    # action will default to 'import' unless specified
    action = ENV['ACTION'] ? ENV['ACTION'] : 'import'
    schools_file = ENV['SCHOOL_FILE']
    school_ids = File.read(schools_file).split(/\n/)
    puts "ACTION #{action}"
    closed_only = ENV['CLOSED_ONLY'].to_s.downcase == 'true'
    params = {
        action: action,
        closed_only: closed_only,
        end_date: ENV['END_DATE'],
        school_ids: school_ids
    }
    GbObjectMigratorWorker.perform_async('Course', params)
  end

  # run the Lesson, Concept and Activity migrations either by invoking the ETL
  # directly or enqueing a sidekiq job that invokes the ETL
  desc 'do migration of Lessons via sidekiq jobs for new gradebook'
  task :migrate_lesson_sidekiq => :environment do |task|
    unless ENV['START_ID']
      puts "USAGE: rake #{task} START_ID=<starting M3 id for Lesson records> END_ID=<ending M3 id for Lesson records> ACTION=<import|add_update|delete>"
      exit
    end

    puts "Migrating Lessons to SQS via sidekiq for env #{Rails.env}\n\n"
    # action will default to 'import' unless specified
    action = ENV['ACTION'] ? ENV['ACTION'] : 'import'
    puts " start_id: #{ENV['START_ID']} end_id: #{ENV['END_ID']} action: #{action} "
    params = { :start_id => ENV['START_ID'], :end_id =>  ENV['END_ID'], :action => action  }
    GbObjectMigratorWorker.perform_async('Lesson', params)
  end

  desc 'do migration of Concepts via sidekiq jobs for new gradebook'
  task :migrate_concept_sidekiq => :environment do |task|
    unless ENV['START_ID']
      puts "USAGE: rake #{task} START_ID=<starting M3 id for Concept records> END_ID=<ending M3 id for Concept records> ACTION=<import|add_update|delete>"
      exit
    end

    action = ENV['ACTION'] ? ENV['ACTION'] : 'import'
    puts "Migrating Concepts to SQS via sidekiq for env #{Rails.env}\n\n"
    puts " start_id: #{ENV['START_ID']} end_id: #{ENV['END_ID']} action: #{action}"
    params = { :start_id => ENV['START_ID'], :end_id =>  ENV['END_ID'], :action => action }
    GbObjectMigratorWorker.perform_async('Concept', params)
  end


  desc 'do migration of Activities via sidekiq jobs for new gradebook'
  task :migrate_activity_sidekiq => :environment do |task|
    unless ENV['START_ID']
      puts "USAGE: rake #{task} START_ID=<starting M3 id for Activity records> END_ID=<ending M3 id for Activity records> ACTION=<import|add_update|delete>"
      exit
    end

    puts "Migrating Activities to SQS via sidekiq for env #{Rails.env}\n\n"
    action = ENV['ACTION'] ? ENV['ACTION'] : 'import'
    puts " start_id: #{ENV['START_ID']} end_id: #{ENV['END_ID']} action: #{action}"
    params = { :start_id => ENV['START_ID'], :end_id =>  ENV['END_ID'], :action => action }
    GbObjectMigratorWorker.perform_async('Activity', params)
  end


  # run ETLs for Concept, Lesson and Activity providing ID ranges
  desc 'do Concepts ETL for new gradebook'
  task :migrate_concept_etl => :environment do |task|
    unless ENV['START_ID']
      puts "USAGE: rake #{task} START_ID=<starting M3 id for Concept records> END_ID=<ending M3 id for Concept records> ACTION=<import|add_update|delete>"
      exit
    end
    action = ENV['ACTION'] ? ENV['ACTION'] : 'import'
    puts "Migrating Concepts to SQS within id range #{ENV['START_ID']} to #{ENV['END_ID']} action: #{action} for env #{Rails.env}\n\n"
    params = { :start_id => ENV['START_ID'], :end_id =>  ENV['END_ID'], :action => action }
    Kiba.run(Etl::ConceptEtl.setup(params))
  end

  desc 'do Lessons ETL for new gradebook'
  task :migrate_lesson_etl => :environment do |task|
    unless ENV['START_ID']
      puts "USAGE: rake #{task} START_ID=<starting M3 id for Lesson records> END_ID=<ending M3 id for Lesson records> ACTION=<import|add_update|delete>"
      exit
    end
    action = ENV['ACTION'] ? ENV['ACTION'] : 'import'
    puts "Migrating Lesson data to SQS within id range #{ENV['START_ID']} to #{ENV['END_ID']} ACTION: #{action} for env #{Rails.env}\n\n"
    params = { :start_id => ENV['START_ID'], :end_id =>  ENV['END_ID'], :action => action }
    Kiba.run(Etl::LessonEtl.setup(params))
  end

  desc 'do Activities ETL for new gradebook'
  task :migrate_activity_etl => :environment do |task|
    unless ENV['START_ID']
      puts "USAGE: rake #{task} START_ID=<starting M3 id for Activity records> END_ID=<ending M3 id for Activity records> ACTION=<import|add_update|delete>"
      exit
    end
    action = ENV['ACTION'] ? ENV['ACTION'] : 'import'
    puts "Migrating Activity data to SQS within id range #{ENV['START_ID']} to #{ENV['END_ID']} ACTION: #{action}for env #{Rails.env}\n\n"
    params = { :start_id => ENV['START_ID'], :end_id =>  ENV['END_ID'], :action => action }
    Kiba.run(Etl::ActivityEtl.setup(params))
  end

  # For testing purposes these tasks are useful to run all other object ETLs
  # directly, Sections for a specified Course; Category, Enrollment, Assignment,
  # Score and User for a specified Section
  desc 'do Sections ETL for new gradebook'
  task :migrate_section_etl => :environment do |task|
    unless ENV['COURSE_ID']
      puts "USAGE: rake #{task} COURSE_ID=<course id> "
      exit
    end

    puts "Migrating to SQS sections and related data for course: #{ENV['COURSE_ID']} for env #{Rails.env}\n\n"
    params = { :course_id => ENV['COURSE_ID'] }
    Kiba.run(Etl::SectionEtl.setup(params))
  end

  desc 'do Categories ETL for new gradebook'
  task :migrate_category_etl => :environment do |task|
    unless ENV['COURSE_ID']
      puts "USAGE: rake #{task} COURSE_ID=<course id> "
      exit
    end

    puts "Migrating to SQS category data for course: #{ENV['COURSE_ID']} for env #{Rails.env}\n\n"
    params = { :course_id => ENV['COURSE_ID'] }
    Kiba.run(Etl::CategoryEtl.setup(params))
  end

  desc 'do Enrollments ETL for new gradebook'
  task :migrate_enrollment_etl => :environment do |task|
    unless ENV['SECTION_ID']
      puts "USAGE: rake #{task} SECTION_ID=<section id> "
      exit
    end

    puts "Migrating to SQS enrollment data for section: #{ENV['SECTION_ID']} for env #{Rails.env}\n\n"
    params = { :section_id => ENV['SECTION_ID'] }
    Kiba.run(Etl::EnrollmentEtl.setup(params))
  end

  desc 'do Assignments ETL for new gradebook'
  task :migrate_assignment_etl => :environment do |task|
    unless ENV['SECTION_ID']
      puts "USAGE: rake #{task} SECTION_ID=<section id> "
      exit
    end

    puts "Migrating to SQS assignment data for section: #{ENV['SECTION_ID']} for env #{Rails.env}\n\n"
    params = { :section_id => ENV['SECTION_ID'] }
    Kiba.run(Etl::AssignmentEtl.setup(params))
  end

  desc 'do Scores ETL for new gradebook'
  task :migrate_score_etl => :environment do |task|
    unless ENV['SECTION_ID']
      puts "USAGE: rake #{task} SECTION_ID=<section id> "
      exit
    end

    puts "Migrating to SQS score data for section: #{ENV['SECTION_ID']} for env #{Rails.env}\n\n"
    params = { :section_id => ENV['SECTION_ID'] }
    Kiba.run(Etl::ScoreEtl.setup(params))
  end

  desc 'do Users ETL for new gradebook'
  task :migrate_user_etl => :environment do |task|
    unless ENV['SECTION_ID']
      puts "USAGE: rake #{task} SECTION_ID=<section id> "
      exit
    end

    puts "Migrating to SQS user data for section: #{ENV['SECTION_ID']} for env #{Rails.env}\n\n"
    params = { :section_id => ENV['SECTION_ID'] }
    Kiba.run(Etl::UserEtl.setup(params))
  end

  desc 'do SQS import ETL for new gradebook'
  task sqs_etl_import: :environment do |task|
    unless ENV['NUM_MESSAGES']
      puts "USAGE: rake #{task} NUM_MESSAGES=<number of messages to read in " \
           'a batch> [NUM_BATCHES=<number of batches to run, default: 1>]'
      exit
    end

    puts "Importing and transforming data in env #{Rails.env}\n\n"
    (ENV['NUM_BATCHES'] || 1).to_i.times do
      Kiba.run(Etl::GradebookImport::MessageEtl.setup(ENV['NUM_MESSAGES'].to_i))
    end
  end

  # this job uses sidekiq to import from SQS
  desc 'do import ETL via sidekiq jobs for new gradebook'
  task :sqs_sidekiq_import => :environment do |task|
    unless ENV['SIDEKIQ_WORKERS']
      puts "USAGE: rake #{task} SIDEKIQ_WORKERS=<concurrent sidekiq workers> NUM_MESSAGES=<number of messages each worker will read in a batch> "
      exit
    end

    puts "Sidekiq job importing and transforming data in env #{Rails.env}\n\n"
    num_workers = ENV['SIDEKIQ_WORKERS'].to_i
    (1..num_workers).each do
      GradebookImportWorker.perform_async(ENV['NUM_MESSAGES'].to_i)
    end
  end
end
