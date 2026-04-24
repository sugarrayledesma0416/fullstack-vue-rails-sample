namespace :submission_api do
  desc 'Migrate Xml to files S3 bucket'
  task migrate_xml_to_s3: :environment do |cmd_name|
    MAX_MIGRATION_THREADS = 16
    response_xml_path = File.join('datafiles', Rails.env, 'responses')
    bucket_path = File.join('datafiles', M3::Application.config.current_deployed_env_name, 'responses')
    uploaded_responses_path = File.join('datafiles', Rails.env, 'uploaded_responses')
    migration_log = Logger.new('/tmp/migrate_xml_to_s3.log')
    files_to_upload = []
    process_response_path(response_xml_path) do |section_dir|
      process_response_path(section_dir) do |local_file_path|
        files_to_upload << local_file_path
      end
    end
    upload_futures = []
    files_to_upload.each_slice(MAX_MIGRATION_THREADS) do |files_chunck|
      upload_future = Concurrent::Future.new do
        files_chunck.each do |local_file_path|
          # upload file_name to S3
          s3_bucket = Radner::S3Storage.new(Radner.profile_name,
                                            Radner.bucket_name,
                                            Radner.region_name,
                                            Radner.use_aws_credentials)
          remote_path = local_file_path.gsub(response_xml_path, bucket_path)
          uploaded_log_path = local_file_path.gsub(response_xml_path,
                                                   uploaded_responses_path)
          unless File.exist?(uploaded_log_path)
            if s3_bucket.upload_file(remote_path, local_file_path)
              dir_name = File.dirname(uploaded_log_path)
              FileUtils.mkdir_p(dir_name) unless File.exist?(dir_name)
              FileUtils.touch(uploaded_log_path)
            else
              message = "could not upload to #{remote_path}: #{s3_bucket.upload_error}"
              migration_log.info(message)
            end
          end
        end
      end
      upload_future.execute
      upload_futures << upload_future
    end

    loop do
      sleep(300)
      all_threads_ended = upload_futures.inject(true) do |memo, upload_future|
        memo && upload_future.complete?
      end
      break if all_threads_ended
    end
  end

  def process_response_path(path)
    Dir.foreach(path) do |file_name|
      next if ['.', '..'].include?(file_name)
      yield File.join(path, file_name)
    end
  end
end
