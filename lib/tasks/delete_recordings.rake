namespace :delete_recordings do
  desc 'Delete recordings based on user_id'
  task :delete, [:user_id] => :environment do |delete, user_id|
    @s3_connection = Aws::S3::Client.new
    @dynamo_table = Aws::DynamoDB::Table.new('audio-recordings')
    @user_id = user_id['user_id'].to_i

    def get_recording_paths
      results = @dynamo_table.scan({
        index_name: "user_id_index",
        attributes_to_get: ["s3_path"],
        scan_filter: {
          user_id: {attribute_value_list: [@user_id],
                    comparison_operator: "EQ"}
        }
      })
      delete_recordings(results)
      #If more records exist than were returned, last_evaluated_key is true
      #Otherwise, it is nil and we can stop after processing the current batch
      if !results.last_evaluated_key.nil?
        get_recording_paths
      end
    end

    def get_target_bucket(s3_path)
      bucket_prefix = s3_path.split('/')[0]
      Rails.application.config.multimedia[bucket_prefix].cdn_prefix[8..-2]
    end

    def delete_recordings(results)
      results['items'].each do |result|
        s3_path = result['s3_path']
        begin
          target_bucket = get_target_bucket(s3_path)
          @s3_connection.delete_object({
            bucket: target_bucket,
            key: s3_path
          })
          @dynamo_table.delete_item({
            key: {
              s3_path: s3_path
            }
          })
        rescue
          puts "Unable to process recording #{s3_path}"
        end
      end
    end
    get_recording_paths
  end
end
