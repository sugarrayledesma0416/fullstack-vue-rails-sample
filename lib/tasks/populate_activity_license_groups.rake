
namespace :activities do
  desc "populates activity records with license group ids"
  task :populate_license_groups => :environment do
    require 'csv'

    csv_path = File.join('db', 'license_group_ids_by_component_name.csv')

    FasterCSV.foreach(csv_path, :headers => true,  :header_converters => :symbol) do |row|
      next if ENV['program_id'].present? && (row[:book_id] != ENV['program_id'])

      lessons = Program.find(row[:book_id]).lessons
      conditions = { :lesson_id => lessons, :component_name => row[:component_name] }

      updated_count = Activity.update_all({:license_group_id => row[:license_group_id]}, conditions)
      puts "updated #{updated_count} entries for #{row[:book_id]}:#{row[:component_name]}"
    end

  end
end
