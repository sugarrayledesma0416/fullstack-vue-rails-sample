require_relative 'study_plan_fixer'

namespace :study_plan do
  desc "Fixes study plan practice test activities which StudyPlanConcepts were not created on publishing"
  task :generate_missing_concepts_and_readings => :environment do |cmd_name|
    if ENV['dry_run'].nil?
      puts "Usage: #{cmd_name} dry_run=true|false"
      exit
    end

    if ENV['dry_run'].downcase == 'true'
      puts 'Running in dry mode'
      StudyPlanFixer.new.dry_run
    elsif ENV['dry_run'].downcase == 'false'
      puts 'Fixing missing concepts and readings'
      StudyPlanFixer.new.fix
    else
       puts "Usage: #{cmd_name} dry_run=true|false"
    end
  end
end
