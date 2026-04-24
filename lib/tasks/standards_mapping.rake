require_relative 'standards_mapping/standard_guid_parser.rb'

namespace :standards_mapping do
  desc 'Create local cache of the standards from an API call to the vendors endpoint'
  task create: :environment do |_task|
    start = Time.zone.now
    processor = StandardsMapping::StandardsProcessor.new
    processor.save_process
    finish = start - Time.zone.now
    Rails.logger.info finish / 60
  end

  desc 'Number unnumbered standards'
  task number_standards: :environment do |_task|
    vendor_std_set_guid = ENV["std_set_guid"]
    unless vendor_std_set_guid
      puts 'USAGE: rake standards_mapping:number_standards std_set_guid=<some guid>'
      exit
    end
    start = Time.zone.now
    processor = StandardsMapping::StandardsProcessor.new
    processor.number_standards(vendor_std_set_guid)
    finish = start - Time.zone.now
    Rails.logger.info finish / 60
  end

  desc 'Set standards with no number and label to not searchable'
  task set_no_number_label_non_searchable: :environment do |_task|
    Standard.where(number: '', label: '').in_batches do |std|
      std.update_all searchable: false
      sleep(0.01)
    end
  end

  desc 'Generate a csv of all activities or assessments in a program'
  task generate_csv: :environment do |task|
    type = ENV['type']
    program_id = ENV['program_id']
    unless Program.find_by(id: program_id) && ['Activity', 'Assessment'].include?(type)
      puts 'USAGE: rake standards_mapping:generate_csv program_id=<program_id> type=<Assessment|Activity>'
      exit
    end

    csv = StandardsMapping::CsvGenerator.new(program_id, type)
    csv.generate!
    print "CSV generated: #{csv.filepath}\n"
  end

  desc 'Prepend parent description to child description'
  task prepend_parent_description: :environment do |_task|
    vendor_std_set_guid = ENV["std_set_guid"]
    unless vendor_std_set_guid
      puts 'USAGE: rake standards_mapping:prepend_parent_description std_set_guid=<some guid>'
      exit
    end
    start = Time.zone.now
    processor = StandardsMapping::StandardsProcessor.new
    processor.prepend_parent_description(vendor_std_set_guid)
    finish = start - Time.zone.now
    Rails.logger.info finish / 60
  end

  desc 'Prep Standards after an AB update - number unnumbered, prepend parent description, append child description, '
        'set searchable to false for leaf node children.'
       'This is only used for WIDA standards at the moment.'
       ' USAGE: rake standards_mapping:prep_after_update std_set_guid=<some guid>'
  task prep_after_update: :environment do |_task|
    vendor_std_set_guid = ENV["std_set_guid"]
    unless vendor_std_set_guid
      puts 'USAGE: rake standards_mapping:prep_after_update std_set_guid=<some guid>'
      exit
    end
    start = Time.zone.now
    processor = StandardsMapping::StandardsProcessor.new
    Rails.logger.info 'Numbering unnumbered standards'
    processor.number_standards(vendor_std_set_guid)
    Rails.logger.info 'Prepending parent description to child description'
    processor.prepend_parent_description(vendor_std_set_guid)
    Rails.logger.info 'Numbering; appending leaf node children\'s descriptions to parent description; setting leaf node children to unsearchable'
    processor.append_leaf_node_descriptions(vendor_std_set_guid)
    finish = start - Time.zone.now
    Rails.logger.info finish / 60
  end

  desc 'Appends leaf node children\'s descriptions to parent description'
       'sets leaf node children to unsearchable'
  task append_child_description_to_parent: :environment do |_task|
    vendor_std_set_guid = ENV["std_set_guid"]
    unless vendor_std_set_guid
      puts 'USAGE: rake standards_mapping:append_child_description_to_parent std_set_guid=<some guid>'
      exit
    end
    start = Time.zone.now
    processor = StandardsMapping::StandardsProcessor.new
    processor.append_leaf_node_descriptions(vendor_std_set_guid)
    finish = start - Time.zone.now
    Rails.logger.info finish / 60
  end
end
