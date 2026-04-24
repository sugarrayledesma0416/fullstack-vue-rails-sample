namespace :s3bucket_cleanup do
  desc 'Clean up unwanted files (Fixnum for name/all the same size)  in the audio/lossless bucket'
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
        if bad_file.key.to_i != 0 && bad_file.size == 44
          @s3_connection.delete_object({
            bucket: @target_bucket,
            key: bad_file.key
          })
        end
      end
    end
    get_bucket_objects
  end
end
