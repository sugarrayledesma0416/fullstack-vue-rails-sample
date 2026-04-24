class SoloVideoRecordingUploader
  include Radner::FilesS3Bucket
  include VonageS3Config

  USER_UPLOADS_PATH = 'user-uploads'.freeze
  DYNAMODB_STATS_INDEX = 'vhl-chat-server-dynamodb'.freeze
  DYNAMODB_TABLE = 'tokbox-recordings'.freeze

  def initialize(user)
    @user = user
  end

  def upload(params)
    video_uploader = VideoUploader.new(params).upload
    video_uploader_results = video_uploader.result
    results = if video_uploader_results[:success]
                # video_was_uploaded_to temp path
                final_file_path = create_destination_path(
                  video_uploader.uuid,
                  video_uploader_results[:original_filename]
                )
                s3_bucket.move_file(
                  video_uploader_results[:temp_file_path],
                  final_file_path
                ) # move file to the final destination
                dynamo_db_data = {
                  archive_id: final_file_path,
                  activity_id: params[:activity_id],
                  school_id: JSON.parse(params[:school_ids]).first,
                  course_id: params[:course_id],
                  status: 'stopped',
                  user_1: { id: params[:user_id].to_s, section_id: params[:section_id].to_s },
                  user_1_id: params[:user_id].to_i
                }
                dynamodb_wrapper.put(new_item: dynamo_db_data) # write to dynamodb
                {
                  success: true,
                  original_filename: video_uploader_results[:original_filename],
                  new_file_name: File.basename(final_file_path),
                  uuid: video_uploader.uuid,
                  final_file_path: final_file_path,
                  s3_signed_url: PartnerChatUrl.new(relative_url: final_file_path).signed_url
                } # create the signed_url
              else
                video_uploader_results
              end
    results
  end

  def delete_video(uuid, file_name)
    file_to_delete = File.join(USER_UPLOADS_PATH, uuid, file_name)
    dynamo_results = dynamodb_wrapper.find(
      primary_key: [archive_id: file_to_delete],
      selected_attributes: ['user_1_id']
    )
    if dynamo_results.present? && dynamo_results.first['user_1_id'].to_i == @user.id
      bucket_result = s3_bucket.delete_file(file_to_delete).delete_marker
      if bucket_result
        dynamodb_wrapper.delete_item(primary_key: { archive_id: file_to_delete })
      end
      bucket_result
    else
      false
    end
  end

  def recording_size(recording_path)
    if recording_path.present?
      s3_bucket.content_length(recording_path)
    else
      0
    end
  end

  private def dynamodb_wrapper
    @dynamodb_wrapper ||= DynamoWrapper.new(
      table: DYNAMODB_TABLE,
      loggers: [
        DynamoWrapper::LogStashLogger.new(
          stats_index: DYNAMODB_STATS_INDEX,
          dynamo_table: DYNAMODB_TABLE
        ),
        DynamoWrapper::DatadogLogger.new
      ]
    )
  end

  private def user_uploads_temp_path
    File.join('tmp', 'uploads')
  end

  private def create_destination_path(uuid, original_filename)
    File.join(
      USER_UPLOADS_PATH,
      uuid,
      "archive#{File.extname(original_filename)}"
    ).to_s
  end
end
