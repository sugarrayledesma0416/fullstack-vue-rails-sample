namespace :media_items do
  namespace :upload do
    desc 'Upload all video/audio media items to the cdn'
    task :all => :environment do
      $stdout = File.open('log/media_uploader.log', 'w')

      # Specific ids can be passed in
      media_item_ids = nil
      if ENV['media_item_ids'].present?
        media_item_ids = ENV['media_item_ids'].split(',').map(&:to_i)
      end

      # Force specific ids to be uploaded
      force = ENV['force'] == 'true'

      if media_item_ids && force
        items_to_upload = MediaItem.find(media_item_ids)
        # don't want to save the change to the bit,
        # otherwise we will enqueue a delayed job
        items_to_upload.each { |media_item| media_item.cdn = false }
      elsif media_item_ids
        items_to_upload = MediaItem.uploadable_to_cdn.find(media_item_ids)
      else
        items_to_upload = MediaItem.uploadable_to_cdn.all
      end

      bar = RakeProgressbar.new(items_to_upload.size)

      items_to_upload.each do |media_item|
        uploader = MediaUploader.new(media_item)
        uploader.upload
        bar.inc
      end
      bar.finished
    end
  end

  namespace :video_files do
    desc 'dump video files information that are linked to activities for a given program'
    task :retrieve_by_program => :environment do
      program = Program.find_by_id(ENV['program_id'])
      unless program.present?
        puts "USAGE: rake #{task} program_id=<program id number>"
        exit
      end

      LiveData::MediaItem.new(program).retrieve_video_file_data

    end
  end
end
