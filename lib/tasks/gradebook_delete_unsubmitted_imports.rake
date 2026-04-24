namespace :gradebook_v2 do
  # Migrate a batch of Courses along with related Sections, Categories,
  # Enrollments, Assignments, Scores and Users.
  desc 'do Course migration ETL directly for new gradebook'
  task :delete_unsubmitted_imports => :environment do |task|
    unless ENV['SECTION_ID_FILE']
      puts "USAGE: rake #{task} SECTION_ID_FILE=<path to file with IDs to run>"
      exit
    end

    filepath = ENV['SECTION_ID_FILE']
    File.open(filepath, 'r').map { |line| line.strip.to_i }.each do |section_id|
      GbDeleteUnsubmittedImportsWorker.perform_async(section_id)
    end
  end
end
