namespace :media_items do
  cdn_logfile = 'tmp/cdn_to_true_media_ids.json'
  safe_media_types = ['image', 'audio', 'video', 'swf', 'subtitle', 'xml']

  namespace :cdn do
    desc 'Flip cdn bit to true for safe media'
    task :on => :environment do
      media_items = MediaItem.where(cdn: false, media_type: safe_media_types)
      media_items_ids = media_items.map(&:id)
      File.open(cdn_logfile, 'w') do |fh|
        fh.write(media_items_ids.to_json)
      end

      begin
        ActiveRecord::Base.transaction do
          media_items_ids.each_slice(2500) do |batch|
            MediaItem.where(id: batch).update_all(cdn: true)
          end
        end
      rescue StandardError => e
        puts "Error encountered. Aborting..."
        puts e.message
      else
        puts "#{media_items.size} media records updated (cdn = true)."
      end
    end
  end

  namespace :cdn do
    desc 'Flip cdn bit to false for safe media that was flipped to true'
    task :off => :environment do
      begin
        ids = JSON.parse(File.read(cdn_logfile))
      rescue StandardError => e
        puts e.message
        puts "Did you run 'rake media_items:cdn:on'?"
        exit
      end

      #media_items = MediaItem.where(id: ids, media_type: safe_media_types)

      begin
        ActiveRecord::Base.transaction do
          ids.each_slice(2500) do |batch_of_ids|
            MediaItem.where(id: batch_of_ids, media_type: safe_media_types).update_all(cdn: false)
          end
        end
      rescue StandardError => e
        puts "Error encountered. Aborting..."
        puts e.message
      else
        puts "#{media_items.size} media records updated (cdn = false)."
      end

    end
  end
end
