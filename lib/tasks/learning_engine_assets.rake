# encoding: utf-8
namespace :learning_engine do
  # rake learning_engine_assets:import program_id=1 assets='json'
  desc "Create a learning engine activity"
  task :import => :environment do |cmd_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{cmd_name} program_id=<program_id>"
      exit(1)
    end

    activity = LearningEngineAssets.new(ENV['program_id']).import

    puts "#{activity.title} created! Id: #{activity.id}"
    puts "Location of activity xml: #{activity.content_filepath}"
  end

  desc "Create a learning engine activity with one checkpoint"
  task :import_with_one_checkpoint => :environment do |cmd_name|
    if ENV['program_id'].blank? || ENV['checkpoint'].blank?
      puts "usage: rake #{cmd_name} program_id=<program_id> checkpoint=<checkpoint_name>"
      exit(1)
    end

    activity = LearningEngineAssets.new(ENV['program_id']).import_with_one_checkpoint("#{ENV['checkpoint']}.xml")

    puts "#{activity.title} created! Id: #{activity.id}"
    puts "Location of activity xml: #{activity.content_filepath}"
  end
end

