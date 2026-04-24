module LiveData
  class MediaItem
    attr_accessor :program

    def initialize(program)
      self.program = program
    end

    def retrieve_video_file_data
      video_csv = FasterCSV.generate(:encoding => 'u') do |csv_data|
        csv_data << ['Activity ID', 'CMS Activity ID', 'Lesson', 'Strand', 'Activity title', 'Video URL']

        video_activities.each do |activity|
          csv_data << [ activity.id,
                        activity.cms_activity_id,
                        activity.lesson.name,
                        activity.strand.title,
                        HTMLEntities.new.decode(activity.title.strip_tags),
                        video_path(activity.content_object) ]
        end
      end

      puts "data dump to #{write_csv_file(video_csv)}"
    end

    def write_csv_file(video_csv)
      file_name = "/tmp/program_#{program.id}_video_data_#{Time.now.strftime("%m_%d_%Y")}.csv"
      File.open(file_name, 'w') do |f|
        f.write(video_csv)
      end

      file_name
    end


    def video_path(content_object)
      if content_object.has_low_res_video?
        video_media_item = content_object.low_res_video.media_item
      elsif content_object.has_high_res_video?
        video_media_item = content_object.high_res_video.media_item
      end

      video_url(video_media_item)
    end
    private :video_path

    def video_url(media_item)
      if media_item.cdn?
        media_item.public_filename
      else
        "http://m3a.vhlcentral.com#{media_item.public_filename}"
      end
    end
    private :video_url

    def video_activities
      Activity.scoped(:conditions => { :lesson_id => program.lessons }).scoped(:conditions => { :activity_type => 'video_v2' })
    end
    private :video_activities

  end
end
