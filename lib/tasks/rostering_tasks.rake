require 'tasks/rostering_tasks'

namespace :rostering_tasks do

  desc "assign ids as guids for some tables; run sql script that adds guids to section_instructors and school_users"
  task :assign_and_load_guids => :environment  do
    puts "Using environment <#{Rails.env}>"
    # If this rake task is run in a production environment it will skip the code where it assigns
    # the id to the guid column.
    # It will only assign guids to section_instructors and school_users and generate the SQL
    # commands file to assign the same ones in M3
    # flag that indicates whether or not to retain the SQL commands file;
    # default is to delete it so as to protect against mistakenly loading an
    # old file which might result in UA and M3 guids mismatch for SchoolUsers and SectionInstructors.
    retain_file =  (!ENV['RETAIN_FILE'].blank? && ENV['RETAIN_FILE'] == 'true') ? true : false
    puts "Retaining SQL input file? #{retain_file}"
    RosteringTasks.new.assign_and_load_guids_from_file(retain_file)
  end

  desc "modify the data in M3 for models that are synchronized via dangerfield
        so the ids do not match those of UA; WILL NOT RUN IN PROD"
  task :modify_test_data_ids => :environment  do
    raise "DO NOT RUN on Live server!!!" if Rails.env.live?
    # DO not run this rake task in a production environment
    puts "Using environment <#{Rails.env}>"
    RosteringTasks.new.modify_database_ids
  end

end