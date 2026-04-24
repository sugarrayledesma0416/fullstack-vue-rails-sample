require 'open-uri'
require_relative 'live_data/course'
require_relative 'live_data/content_stats'
require_relative 'live_data/content'
require_relative 'live_data/user'

namespace :live_data do
  namespace :course do
    desc "export course"
    task :export => :environment do |task|
      course_id = ENV["course_id"]
      unless course_id
        puts "USAGE: rake #{task} course_id=<course id number>"
        exit
      end

      LiveData::Course.new(course_id).export
    end

    desc "import course"
    task :import => :environment do |task|
      course_id = ENV["course_id"]
      unless course_id
        puts "USAGE: rake #{task} course_id=<course id number>"
        exit
      end

      LiveData::Course.new.import(course_id)
    end
  end #end course namespace

  namespace :content do
    desc "download activity xml for local override"
    task :set_activity_content_local => :environment do |task|
      activity_id = ENV['activity_id']
      unless activity_id
        puts "USAGE: rake #{task} activity_id=<activity id number>"
        exit
      end

      LiveData::Content.new.make_activity_content_local(activity_id)
    end


    desc "import content data"
    task :import => :environment do |task|

      LiveData::Content.new.import
    end

    desc "export maestro 3 content data"
    task :export => :environment do |task|

      LiveData::Content.new.export
    end

    desc "refresh local data from live database"
    task :refresh => :environment do |task|
      puts <<-WARNING_MSG.strip_heredoc
        This task will replace all of your content related local data with data
        from the live server. If you have run this task before, your course
        related data should still be valid. If this is your first time bringing
        in live data, any existing course related data will become invalid and will
        need to be removed and regenerated.

      Do you wish to proceed (y/N?)
      WARNING_MSG
      response = STDIN.gets.chomp.downcase

      if response == 'y'
        puts "
          Getting live data..."
        ENV['env'] = 'live'
        Rake::Task['live_data:content:export'].invoke

        puts "
          Replacing local data..."
        ENV['env'] = Rails.env
        Rake::Task['live_data:content:import'].invoke

        puts "
          Task complete."
        puts "
          If you need to reset your course data, run:
            rake local_data:remove_all_course_data"
      else
        puts "Aborting..."
      end
    end
  end

  namespace :content_stats do
    desc "export program content stats"
    task :export => :environment do |task|
      program_id = ENV["program_id"]
      unless program_id
        puts "USAGE: rake #{task} program_id=<program id>"
        exit
      end
     LiveData::ContentStats.new(program_id).export
    end
  end

  namespace :users do
    desc "reset users passwords to 'password'"
    task :reset_all_passwords => :environment do |task|
      LiveData::User.new.reset_all_passwords
    end
  end

end
