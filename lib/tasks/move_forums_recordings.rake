namespace :move_forums_recordings do
  desc 'Move existing forums recordings in lossless bucket to the arcaudio bucket'
  task :move_forums => :environment do

    def set_buckets
      @s3_connection = Aws::S3::Client.new
      @buckets = {}

      if Rails.env == 'development'
        @buckets[:org] = 'speech-recognition-samples-lossless-dev'
      elsif Rails.env == 'staging'
        @buckets[:org] = 'speech-recognition-samples-lossless-qa'
      elsif Rails.env == 'live'
        @buckets[:org] = 'speech-recognition-samples-lossless'
      end
      @buckets[:target] = Rails.application.config.multimedia.recording_v2.cdn_prefix[8..-2]
    end

    def retrieve_metadata
      begin
        audio_path = @metadata['s3_path'].gsub("forums/", "")
        forum_post = ForumPost.where(audio_path: audio_path)
        @metadata['user_id'] = forum_post.first.user_id.to_s
        forum = Forum.find(forum_post.first.forum_id)
        section = Section.find(forum.section_id)
        @metadata['section_guid'] = section.guid
        course = Course.find(section.course_id)
        @metadata['school_id'] = course.school_id.to_s
      rescue
        puts "Unable to find metadata for #{@metadata['s3_path']}"
      end
    end

    def copy_recording
      @s3_connection.copy_object({
        bucket: @buckets[:target],
        copy_source: @buckets[:org] + '/' + @metadata['s3_path'],
        key: @metadata['s3_path'],
        metadata: @metadata,
        metadata_directive: 'REPLACE'
      })
    end

    def check_metadata
      existing_recording = @s3_connection.get_object({
        bucket: @buckets[:org],
        key: @metadata['s3_path']
      })
      if existing_recording.metadata.empty?
        retrieve_metadata
      else
        existing_recording.metadata.each do |k, v|
          @metadata[k] = v
        end
      end
      copy_recording
    end

    def process_metadata(bucket_objects)
      bucket_objects.contents.each do |bucket_obj|
        @metadata = {}
        @metadata['s3_path'] = bucket_obj.key
        check_metadata
      end
    end

    def get_all_objects
      @start_after = nil
      bucket_objects = @s3_connection.list_objects_v2({
        bucket: @buckets[:org],
        prefix: 'forums',
        start_after: @start_after
      })
      process_metadata(bucket_objects)
      if bucket_objects.is_truncated
        @start_after = bucket_objects.contents.last.key
        get_all_objects
      end
    end

    set_buckets
    get_all_objects
  end
end

