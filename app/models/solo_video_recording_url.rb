class SoloVideoRecordingUrl
  DYNAMODB_STATS_INDEX = 'vhl-chat-server-dynamodb'.freeze
  DYNAMODB_TABLE = 'tokbox-recordings'.freeze

  def initialize(user)
    @user = user
  end

  def video_signed_url(recording_path)
    partner_chat_permissions = PartnerChatPermissions.new(
      recording_path:,
      dynamodb_wrapper:,
      user: @user
    )
    status_code = partner_chat_permissions.status_code
    signed_url = if partner_chat_permissions.allowed_path.present?
                   generate_partner_chat_signed_url(partner_chat_permissions.allowed_path)
                 end
    { signed_url:, status_code: }
  end

  private def generate_partner_chat_signed_url(relative_path)
    PartnerChatUrl.new(relative_url: relative_path).signed_url
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
end
