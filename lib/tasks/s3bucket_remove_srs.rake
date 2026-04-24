namespace :s3bucket_remove_srs do
  desc 'Clean up old files in the audio/lossless bucket that are not in forums, listen_repeat or learning_engine'
  task :cleanup, [:bucket_name] => :environment do |cleanup, bucket_name|
    @s3_connection = Aws::S3::Client.new
    @target_bucket =  bucket_name['bucket_name']
    @start_after = nil

    def get_bucket_objects
      bucket_objects = @s3_connection.list_objects_v2({
        bucket: @target_bucket,
        start_after: @start_after
      })
      delete_bad_files(bucket_objects)
      if bucket_objects.is_truncated
        @start_after = bucket_objects.contents.last.key
        get_bucket_objects
      end
    end

    def delete_bad_files(bucket_objects)
      for bad_file in bucket_objects.contents
        file_path = bad_file.key
        unless file_path.include?('listen_repeat') || file_path.include?('forums') || file_path.include?('learning_engine')
          @s3_connection.delete_object({
            bucket: @target_bucket,
            key: file_path
          })
        end
      end
    end
    get_bucket_objects
  end
end
