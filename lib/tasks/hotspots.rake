require_relative 'hotspots_generator'

namespace :hotspots do
  # rake hotspots:create program_id=48
  desc "Create a reference activity with image hotspots"
  task :create => :environment do |cmd_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{cmd_name} program_id=<program_id"
      exit(1)
    end

    activity = HotspotsGenerator.new.generate(ENV['program_id'])

    puts "#{activity.title} created! Id: #{activity.id}"
    puts "Location of activity xml: #{activity.content_filepath}"
  end
end

