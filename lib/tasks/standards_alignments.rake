namespace :standards_alignments do
  desc 'Create local cache of the alignments associated with a standard mapped asset'
  task populate_alignments: :environment do |_task|
    start = Time.zone.now
    processor = StandardsMapping::AlignmentsProcessor.new.import_new_assets
    finish = start - Time.zone.now
    Rails.logger.info finish / 60
  end

  desc 'Update local cache with added or deleted alignments for assets'
  task update_alignments: :environment do |_task|
    program_id = ENV["program_id"]
    unless program_id
      puts 'USAGE: rake standards_alignments:update_alignments program_id=<program_id>'
      exit
    end
    start = Time.zone.now
    StandardsMapping::AlignmentsProcessor.new.import_updated_alignments(program_id)
    finish = start - Time.zone.now
    Rails.logger.info finish / 60
  end
end
