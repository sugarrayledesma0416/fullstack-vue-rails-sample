namespace :recording_metadata do
  desc 'Update user_id and school_id metadata for S3 bucket recordings'
  task :update, [:folder, :start_after] => :environment do |update, args|
    @folder_name = args['folder']
    @start_after = args['start_after'] || nil
    @target_bucket = Rails.application.config.multimedia[@folder_name].cdn_prefix[8..-2]
    @s3_connection = Aws::S3::Client.new
    @metadata_processing_log = Logger.new('/tmp/recording_metadata_update.log')

    def get_all_objects
      @bucket_objects = @s3_connection.list_objects_v2({
        bucket: @target_bucket,
        prefix: @folder_name,
        start_after: @start_after
      })
      process_objects
      if @bucket_objects.is_truncated
        begin
          @start_after = @bucket_objects.contents.last.key
          get_all_objects
        rescue
          @metadata_processing_log.error("Last record processed key: #{@start_after}")
        end
      end
    end

    def get_bucket_metadata(s3_path)
      bucket_metadata = @s3_connection.head_object({
        bucket: @target_bucket,
        key: s3_path})
      @obj_metadata = bucket_metadata.metadata
    end

    def get_school_id
      if Course.exists?(guid: @obj_metadata['course_guid'])
        Course.where(guid: @obj_metadata['course_guid']).first.school_id
      end
    end

    def get_user_id
      if User.exists?('guid': @obj_metadata['user_guid'])
        User.where('guid': @obj_metadata['user_guid']).first.id
      end
    end

    def update_metadata(s3_path, user_id, school_id)
      metadata = {}
      metadata['s3_path'] = s3_path
      metadata['section_guid'] = @obj_metadata['section_guid'] || ''
      metadata['course_guid'] = @obj_metadata['course_guid'] || ''
      metadata['school_id'] = school_id.to_s
      metadata['activity_id'] = @obj_metadata['activity_id'] || ''
      metadata['lesson_id'] = @obj_metadata['lesson_id'] || ''
      metadata['user_guid'] = @obj_metadata['user_guid'] || ''
      metadata['user_id'] = user_id.to_s
      @s3_connection.copy_object({
        bucket: @target_bucket,
        copy_source: @target_bucket + '/' + s3_path,
        key: s3_path,
        metadata: metadata,
        metadata_directive: 'REPLACE'
      })
      @metadata_processing_log.info("Processed record #{s3_path}")
    end

    def process_objects
     @bucket_objects.contents.each do |bucket_obj|
        get_bucket_metadata(bucket_obj.key)
        school_id = nil
        user_id = nil
        if (!@obj_metadata.key?('school_id') || @obj_metadata['school_id'].blank?) && !@obj_metadata['course_guid'].nil?
          school_id = get_school_id
        else
          school_id = @obj_metadata['school_id']
        end
        if (!@obj_metadata.key?('user_id') || @obj_metadata['user_id'].blank?) && !@obj_metadata['user_guid'].nil?
          user_id = get_user_id
        else
          user_id = @obj_metadata['user_id']
        end
        if (school_id && !school_id.nil?) || (user_id && !user_id.nil?)
          update_metadata(bucket_obj.key, user_id, school_id)
        end
      end
    end
    get_all_objects
  end
end
