require_relative 'learning_track/group_set_generator'

namespace :learning_tracks do
  def require_vars_for(cmd_name, *env_vars)
    missing_params = env_vars.select do |env_var|
      ENV[env_var].blank?
    end
    unless missing_params.empty?
      puts "#{cmd_name} is missing the following parameters: " + missing_params.join(", ")
      exit(1)
    end
  end

  # rake learning_tracks:generate_group_set program_id=48
  desc "Generate a group set CSV template"
  task :generate_group_set => :environment do |cmd_name|
    require_vars_for cmd_name, 'program_id'
    program = Program.find(ENV['program_id'])
    group_set_generator = LearningTrack::GroupSetGenerator.new(program)
    group_set_generator.write_csv
  end

  # rake learning_tracks:import_group_set filename=group_set.xlsx program_id=48
  desc "Imports a set of track groups from a CSV"
  task :import_group_set => :environment do |cmd_name|
    require_vars_for cmd_name, 's3_file_path', 'program_id'
    program = Program.find(ENV['program_id'])
    group_set_importer = LearningTrack::GroupSetImporterV2.new(program)
    group_set_importer.import(ENV['s3_file_path'])
    cmd_name.reenable
  end

  # rake learning_tracks:export_activities program_id=48
  desc "Exports all activities from a program as JSON"
  task :export_activities => :environment do |cmd_name|
    require_vars_for cmd_name, 'program_id'
    program = Program.find(ENV['program_id'])
    activity_exporter = LearningTrack::ActivityExporter.new(program)
    activity_exporter.write_activities_json
  end

  # rake learning_tracks:export_track track_filename=learning_track_activities.xlsx track_family_filename=learning_track_specs.xlsx program_id=48 course_package_ids=1,2,3
  desc "Exports a real learning track from a CSV"
  task :export_track => :environment do |cmd_name|
    require_vars_for cmd_name, 'track_filename', 'track_family_filename', 'program_id', 'course_package_ids'
    course_package_ids = ENV['course_package_ids'].split(',').map(&:to_i)
    program = Program.find(ENV['program_id'])
    learning_track_exporter = LearningTrack::LearningTrackExporter.new(program)
    learning_track_exporter.write_learning_track_json(ENV['track_filename'], ENV['track_family_filename'], course_package_ids)
    # Rake will, by default, ensure that each rake task is executed once and only once per session
    # We need to reenable it to run it again from a loop
    cmd_name.reenable
  end

  # rake learning_tracks:export_categories filename=grade_set_categories.xlsx program_id=48
  desc "Exports category sets from a CSV"
  task :export_categories => :environment do |cmd_name|
    require_vars_for cmd_name, 'file_name', 'program_id'
    program = Program.find(ENV['program_id'])
    category_exporter = LearningTrack::CategoryExporter.new(program)
    categories_file_path = category_exporter.file_path(ENV['file_name'])
    unless category_exporter.file_exists?(categories_file_path)
      puts "#{categories_file_path} not found for #{cmd_name}"
      exit(1)
    end
    category_exporter.write_categories_json(ENV['file_name'])
  end

  # To run this rake task, you need:
  # A directory named the program id with:
  # learning_track_specs_*.xlsx
  # learning_track_activities_*.xlsx
  # grade_category_set.xlsx
  # *_group_set.xlsx for any track groups that need to be in the database
  # rake learning_tracks:export_json program_id=40 course_package_ids=1,2,3
  desc "Exports a full learning track json file from csv files for a program id"
  task :export_json => :environment do |cmd_name|
    require_vars_for cmd_name, 'program_id'
    program = Program.find(ENV['program_id'])
    LearningTrack::LearningTrackFileCreator.create(program)
  end

  desc 'Update activities json for all M3 titles'
  task update_activities_for_all_titles: :environment do |cmd_name|
    Program.where(maestro_version: 3).each do |program|
      ENV['program_id'] = program.id.to_s

      rake_task = if program.vista_online_learning?
                    ENV['course_package_ids'] =
                      Maestro::CoursePackage.all(program.id).map(&:id).join(',')

                    'learning_tracks:export_json'
                  else
                    'learning_tracks:export_activities'
                  end

      # When you run Rake::Task.invoke, it's necessary to call .reenable
      # in order to call it again.
      # If we run a rake task with invoke, it will call all the
      # prerequisite task, so we need to call .reenable as well for each prerequisite.

      Rake::Task[rake_task].all_prerequisite_tasks.each(&:reenable)

      # Reenable task if has been called before
      Rake::Task[rake_task].reenable
      Rake::Task[rake_task].invoke
    end
  end
end
