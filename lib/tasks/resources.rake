require_relative 'demo_data/csv'
require_relative 'demo_data/data_file'

namespace :resources do
  desc "Loads files from specified dir and meta information from csv"
  task :import => :environment do
    extend ActionView::Helpers
    extend FileTypeParsable
    include Radner::FilesS3Bucket

    program_id = ENV['program_id'].to_i
    import_dir = File.join('resources/tmp', ENV['program_dir'])
    csv_file   = File.join(import_dir, 'resources_data.csv')
    generic_unit_id = ResourcesTaskHelpers.create_resource_unit_and_lesson(program_id)

    resource_count = 0
    csv_data = s3_bucket.fetch(csv_file)
    DemoData::CSV.rows(csv_data, is_csv_data = true) do |row|
      resource_count += 1
    end

    progress_bar = RakeProgressbar.new(resource_count)

    #other_component = ResourceComponent.find_or_create_by_name(:name => "Other", :program_id => program_id)
    DemoData::CSV.rows(csv_data, is_csv_data = true) do |row|
      source_file_path = row[:source_file_path]

      filename = File.basename(source_file_path)
      ext_name = File.extname(filename)
      description = simple_format(row[:description].html_safe, {}, {:sanitize => false})

      parent_component = ResourceComponent.find_or_create_by(name: row[:component_name], program_id: program_id)

      resource_params = { :title                 => row[:clean_title],
                          :program_id            => program_id,
                          :file_name             => filename,
                          :file_type             => file_type(ext_name),
                          :description           => description,
                          :subcomponent_name     => row[:subcomponent_name],
                          :vhl_student_resource  => (row[:is_student_resource].to_s == '1'),
                          :protected             => (row[:is_protected].to_s == '1'),
                          :resource_component_id => parent_component.id,
                          :source                => 'VHL'
                        }

      if row[:start_unit].blank?
        resource_params[:start_unit_id] = generic_unit_id
      else
        resource_params[:start_unit_id] = ResourcesTaskHelpers.unit_for_resource(row[:start_unit], program_id)
      end

      resource_params[:end_unit_id] = ResourcesTaskHelpers.unit_for_resource(row[:end_unit], program_id) unless row[:end_unit].blank?

      resource = Resource.create!(resource_params)

      source_path = File.join(import_dir, source_file_path)

      resource.upload_file(StringIO.new(s3_bucket.fetch(source_path))) unless resource.has_file?
      progress_bar.inc
    end
    progress_bar.finished
  end

  desc "Validates filenames against csv values before doing an import"
  task :validate => :environment do |task_name|
    resources_dir = ENV['resources_dir']
    program_dir = ENV['program_dir']
    if resources_dir.blank? || program_dir.blank?
      puts "usage: #{task_name} program_dir=<program dir, eg panorama4e> resources_dir=<base resources dir>"
      puts "suggest adding \"export resources_dir=/your/resources/dir\" to .bashrc"
      exit(1)
    end

    resources_dir = File.expand_path(resources_dir)
    import_dir = File.join(resources_dir, program_dir)

    ## if we don't have a resources_data.csv file, find the first csv and copy it to resources_data.csv
    all_csv_files = Dir.glob("#{import_dir}/*.csv")
    raise "no csv file found in #{import_dir}" unless all_csv_files.any?

    csv_file = File.join(import_dir, "resources_data.csv")

    unless all_csv_files.include?(csv_file)
      DemoData::DataFile.copy(all_csv_files.first, csv_file)
    end

    ## if resources_data.csv is not utf8, convert it from windows-1252 to utf8
    csv_data = File.open(csv_file).read
    unless csv_data.is_utf8?
      File.open(csv_file, "w") { |f| f.puts csv_data.encode("UTF-8", "Windows-1252") }
    end

    ## find any csv entries pointing to files that are not on disk
    failures = { :missing_files => [],
                 :invalid_characters => [],
                 :missing_title => [] }
    DemoData::CSV.rows(csv_file) do |row|
      if row[:clean_title].blank?
        failures[:missing_title] << row[:source_file_path]
      end
      source_path = File.join(import_dir, row[:source_file_path])
      unless File.exist?(source_path)
        failures[:missing_files] << row[:source_file_path]
      end
      original_filename = File.basename(row[:source_file_path])
      comparison_filename = original_filename.remove_accents.gsub(/\s/, '_').gsub(/[<>|\/\\:()&;#?*]/, '-')
      if original_filename != comparison_filename
        failures[:invalid_characters] << row[:source_file_path]
      end
    end
    failures.each do |error_type, failure_paths|
      puts "#{error_type}:" if failure_paths.any?
      failure_paths.each{|failure_path| puts "  #{failure_path}" }
    end
  end

  desc "create testing program categories"
  task :setup_tests_categories => :environment do |cmd_name|
    if ENV['program_id'].blank?
      puts "usage: #{cmd_name} program_id=<program id>"
      exit(1)
    end
    program_id = ENV['program_id'].to_i
    testing_program_component = ResourceComponent.where(program_id: program_id, name: 'Testing Program').first
    resources_to_update = Resource.where(program_id: program_id, resource_component_id: testing_program_component.id)

    categories_and_resources = { 'Quizzes' => Array.new,
                                 'Tests and Exams' => Array.new,
                                 'Optional Test Sections' => Array.new,
                                 'Testing Audioscripts' => Array.new,
                                 'Testing Answer Keys' => Array.new,
                                 'Oral Testing Suggestions' => Array.new }
    categories_and_resources['Quizzes'] = resources_to_update.select{ |resource| resource.subcomponent_name == 'Quizzes' }
    categories_and_resources['Tests and Exams'] = resources_to_update.select{ |resource| resource.subcomponent_name == 'Tests' || resource.subcomponent_name == 'Exams' }
    categories_and_resources['Optional Test Sections'] = resources_to_update.select{ |resource| resource.subcomponent_name == 'Optional Test Sections' }
    categories_and_resources['Testing Audioscripts'] = resources_to_update.select{ |resource| resource.subcomponent_name =~ /^Testing Audio Program.*/ }
    categories_and_resources['Testing Answer Keys'] = resources_to_update.select{ |resource| resource.subcomponent_name == 'Testing Program Answer Keys' }
    categories_and_resources['Oral Testing Suggestions'] = resources_to_update.select{ |resource| resource.subcomponent_name == 'Oral Testing Suggestions' }

    progress_bar = ProgressBar.new("updating_resources", categories_and_resources.values.flatten.size)

    categories_and_resources.each_pair do |component_name, resources|
      next if resources.empty?
      parent_component = ResourceComponent.find_or_create_by(name: component_name, program_id: program_id)
      resources.each do |resource|
        resource.update!(:resource_component_id => parent_component.id, :subcomponent_name => '')
        progress_bar.inc
      end
    end
    progress_bar.finish
  end
end

module ResourcesTaskHelpers
  def self.create_resource_unit_and_lesson(program_id)
    program = Program.find_by_id(program_id)
    generic_unit = Unit.find_or_create_by(
      name: "No #{program.unit_label}",
      program_id: program_id, rank: 99,
      label: "No #{program.unit_label}"
    )
    if generic_unit.use_type != "ResourceUnit"
      generic_unit.use_type = "ResourceUnit"
      generic_unit.save!
    end

    lesson = Lesson.find_or_create_by(name: "No #{program.unit_label}", rank: 0, unit_id: generic_unit.id)
    if lesson.use_type != "ResourceLesson"
      lesson.use_type = "ResourceLesson"
      lesson.save!
    end

    generic_unit.id
  end

  def self.unit_for_resource(unit_rank, program_id)
    unit = Unit.where(rank: (unit_rank.to_i - 1), program_id: program_id).first
    unit.id unless unit.nil?
  end
end
