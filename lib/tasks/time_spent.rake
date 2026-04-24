require_relative 'time_spent'

namespace :time_spent do
  # rake time_spent:fix instructor_id=##
  desc "Fixes time spent for a given course or section"
  task :fix => :environment do |cmd_name|
    if ENV['course_id'].blank? && ENV['section_id'].blank?
      puts "usage: rake #{cmd_name} [course_id=<course_id> | section_id=<section_id>] [dry=run]"
      exit(1)
    end

    dry_run = ENV['dry'] == 'run'

    puts 'Dry run...' if dry_run

    course_id = ENV['course_id'].to_i
    section_id = ENV['section_id'].to_i

    begin
      if course_id > 0
        puts TimeSpent.fix_course(course_id, dry_run)
      else
        puts TimeSpent.fix_section(section_id, dry_run)
      end
    rescue StandardError => e
      puts e.message
    end
  end
end
