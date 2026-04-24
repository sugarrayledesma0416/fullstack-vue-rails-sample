namespace :move_speech_rec_lossless do
  desc 'Move existing files in the lossless bucket to the arcaudio bucket'
  task :move_listen_repeat => :environment do

    def activity_ids
      Activity.where(activity_type: 'speech_rec_listen_repeat')
    end

    def process_attempts(attempts)
      results_cacher = ResultsApiDatastore::MultipleAttempts.new(attempts)
      if results_cacher.cacheable?
        attempts.each do |attempt|
          attempt.stored_responses = results_cacher.stored_response(attempt)
          process_submission(attempt.stored_responses)
        end
      end
    end

    def process_submission(submission)
      submission.each_value do |submission_data|
        # The data for each submission is structured as follows:
        # {"word_01"=>
        #   "{\"best_guess\":\"SIL_S i_B n_I t_I i_I k_I a_E SIL_S\",
        #     \"id\":\"s3_path.wav\",
        #     \"rating\":\"not understandable\"}"}
        submission_data_hash = JSON.parse(submission_data)
        if submission_data_hash.has_key?('id')
          @metadata['s3_path'] = 'listen_repeat/' + submission_data_hash['id']
          set_existing_metadata
          copy_recording
        end
      end
    rescue
      puts "Error processing recording: #{@metadata['s3_path']}"
    end

    def find_metadata
      activity_ids.each do |activity|
        @metadata = {}
        @metadata['activity_id'] = activity.id.to_s
        @metadata['lesson_id'] = activity.lesson_id.to_s
        Attempt.where(activity_id: activity.id).where('submission_id IS NOT NULL').find_in_batches(batch_size: 100) do |batch|
          unless batch.empty?
            process_attempts(batch)
          end
        end
      end
    end
    set_buckets
    find_metadata
  end

  desc "Move speech rec recordings created by the learning engine"
  task :move_learning_engine => :environment do
    @start_after = nil

    def get_all_objects
      bucket_objects = @s3_connection.list_objects_v2({
        bucket: @buckets[:org],
        prefix: 'learning_engine',
        start_after: @start_after
      })
      add_metadata(bucket_objects)
      if bucket_objects.is_truncated
        @start_after = bucket_objects.contents.last.key
        get_all_objects
      end
    end

    def add_metadata(bucket_objects)
      bucket_objects.contents.each do |bucket_obj|
        @metadata = {}
        @metadata['s3_path'] = bucket_obj['key']
        unless bucket_obj['key'].include?('empty')
          set_existing_metadata
          # If no existing metadata, then we only send the s3_path and user_id
          # The user_id is the numbers before the first - in the key/s3_path
          if @metadata.length == 1 # The only metadata is the s3_path
            @metadata['user_id'] = bucket_obj['key'].split('/')[-1].split('-')[0]
          end
          copy_recording
        end
      end
    rescue
      puts "Error copying #{@metadata['s3_path']}"
    end
    set_buckets
    get_all_objects
  end

  def set_buckets
    @s3_connection = Aws::S3::Client.new
    @buckets = {}
    @buckets[:target] = Rails.application.config.multimedia.recording_v2.cdn_prefix[8..-2]

    if Rails.env == 'development'
      @buckets[:org] = 'speech-recognition-samples-lossless-dev'
    elsif Rails.env == 'staging'
      @buckets[:org] = 'speech-recognition-samples-lossless-qa'
    elsif Rails.env == 'live'
      @buckets[:org] = 'speech-recognition-samples-lossless'
    end
  end

  def set_existing_metadata
    metadata_dict = @s3_connection.get_object({
      bucket: @buckets[:org],
      key: @metadata['s3_path']
    })
    existing_metadata = metadata_dict['metadata']
    unless existing_metadata.empty?
      existing_metadata.each do |k, v|
        @metadata[k] = v
      end
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
end
