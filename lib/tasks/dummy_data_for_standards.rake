require_relative 'simulated_submissions_for_standards'

namespace :standards_data do
  desc 'generate data for the Standards_results table'
  task generate_standards_results: :environment do |cmd_name|
    activity_id = ENV.fetch('activity_id', nil)
    section_id = ENV.fetch('section_id', nil)
    number_of_students = ENV.fetch('number_of_students', nil)

    if activity_id.nil? || section_id.nil? || number_of_students.nil?
      puts "\nUsage:\n  rails #{cmd_name} " \
           'activity_id=<id> section_id=<id> number_of_students=<1 to 100>'
      abort
    end

    sim = SimulatedSubmissionsForStandards.new(
      activity_id: activity_id.to_i,
      section_id: section_id.to_i,
      number_of_students: number_of_students.to_i
    )
    puts sim.errors.map(&:message) unless sim.process
  end
end
