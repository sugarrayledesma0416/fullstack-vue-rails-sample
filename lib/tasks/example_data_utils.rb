# A container for generic helper utilities used to populate the
# environment. All methods are content-agnostic, meaning that
# all decisions about /what/ to include are elsewhere. This
# provides the /how/.
module ExampleDataUtils
  # Download and install a media item using an existing CMS media item.
  def copy_media_from_cms(media_item_filenames, overwrite_media_items = 'no')
    hosts = ["http://cms.vhlcentral.com"]
    overwrite_media_items ||= 'no'

    media_item_filenames.each do |media_item_filename|
      params = {}
      if media_item_filename.is_a?(Array)
        media_item_filename, params = media_item_filename
      end
      media_item_id_string = "#{media_item_filename[0..3]}#{media_item_filename[5..8]}"
      extension = media_item_filename[-3..-1].downcase
      target_filename = media_item_id_string + "." + extension

      media_type = case extension
                   when 'mp3' then 'audio'
                   when 'mp4' then 'video'
                   when 'flv' then 'video'
                   when 'mov' then 'video'
                   else
                     'image'
                   end
      media_path = (media_type == 'image' ? 'images' : media_type)

      target_path = "public/media_items/" + Rails.env + "/" + media_path +
        "/" + media_item_id_string[0..3] + "/" + target_filename

      if File.exist?(target_path) && overwrite_media_items == 'no'
        puts "  skipping #{target_path}. Already in place."
      else
        downloaded = false
        hosts.each do |host|
          file_uri = URI.parse(host + "/media_items/" + media_item_filename)
          begin
            res = Net::HTTP.start(file_uri.host, file_uri.port) { |http| http.get(file_uri.path) }
          rescue Errno::EHOSTUNREACH => e
            next
          end
          next if (res.code != "200")

          FileUtils.mkdir_p(File.dirname(target_path))
          File.open(target_path, "wb") do |file|
            file.write(res.body)
          end
          downloaded = true
        end
        if !downloaded
          puts "FAILED to download #{media_item_filename}."
        else
          puts "downloaded #{media_item_filename} to #{target_path}."
        end
      end

      update_params = {
        :filename => target_filename,
        :media_type => media_type
      }.merge(params)

      media_item_id = media_item_id_string.to_i
      media_item = MediaItem.find_by_id(media_item_id)
      if media_item
        media_item.update!(update_params)
      else
        media_item = MediaItem.new(update_params)
        media_item.id = media_item_id_string.to_i
        media_item.save!
      end
    end
  end

  def detect_zip_media_type(media_filename)
    case
    when media_filename =~ /.*vocab_tutorial_html5.*zip\z/
      'vocab_tutorial_html5'
    when media_filename =~ /.vocab_tutorial.zip/
      'vocab_tutorial'
    when media_filename =~ /.vocab_group.zip/
      'vocab_group'
    when media_filename =~ /.flash_reading.zip/
      'flash_reading'
    else
      'zip'
    end
  end
end
