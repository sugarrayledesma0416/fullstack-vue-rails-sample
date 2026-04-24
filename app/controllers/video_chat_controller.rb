require 'video_chat/tok_box_wrapper'
require 'partner_chat_cookie'

class VideoChatController < ApplicationController
  include CartridgeViewable

  DYNAMODB_STATS_INDEX = 'vhl-chat-server-dynamodb'.freeze
  DYNAMODB_TABLE = 'tokbox-recordings'.freeze

  before_action :require_user

  def create_session
    tokbox_session = tokbox_wrapper.get_session

    if tokbox_wrapper.errors?
      render json: tokbox_wrapper.errors, status: :forbidden
    else
      render json: tokbox_session, status: :ok
    end
  end

  def create_token
    tokbox_token = tokbox_wrapper.get_token(params[:session_id])
    if tokbox_wrapper.errors?
      render json: tokbox_wrapper.errors, status: :forbidden
    else
      render json: tokbox_token, status: :ok
    end
  end

  # pchat recordings: expect values for user_1 and user_2
  # group chat recordings: expect a users array
  # solo user recordings: expect value for user 1 only
  # if missing user_1 and users then return error
  def start_recording
    tokbox_recording = tokbox_wrapper.record(params[:session_id])
    if tokbox_wrapper.errors?
      render json: tokbox_wrapper.errors, status: :forbidden
    else
      user_1 = user_data(params[:user_1]) if params.has_key?(:user_1)
      user_2 = user_data(params[:user_2]) if params.has_key?(:user_2)
      users = users_list_params if params.has_key?(:users)
      # for this to be a valid request one of these values must be included in the params
      if user_1 || users
        # Create object to be stored on dynamo
        data = {
          archive_id: tokbox_recording[:id], status: 'started',
          school_id: params[:school_id], course_id: params[:course_id],
          activity_id: params[:activity_id]
        }
        data.merge!(user_1_id: user_1[:id].to_i, user_1: user_1) if user_1
        data.merge!(user_2_id: user_2[:id].to_i, user_2: user_2) if user_2
        data.merge!(users: users) if users
        dynamodb_wrapper.put(new_item: data)
        if dynamodb_wrapper.errors?
          render json: dynamodb_wrapper.error_messages, status: :forbidden
        else
          render json: tokbox_recording, status: :ok
        end
      else
        render json: ["Missing user or users parameter"], status: :bad_request
      end
    end
  end

  # Remove 'section' word from the section_id property, leaving only the number.
  private def user_data(user_params)
    user_params.permit(:id, :section_id).to_h.symbolize_keys.merge(section_id: user_params[:section_id].gsub('section_', ''))
  end

  private def users_list_params
    result = params.permit(users: %i[id section_id]).to_h.symbolize_keys
    result[:users].map do |user|
      user.symbolize_keys!.merge(section_id: user[:section_id].gsub('section_', ''))
    end unless result.blank?
  end

  def stop_recording
    tokbox_recording = tokbox_wrapper.stop_recording(params[:session_id], params[:recording_id])

    if tokbox_wrapper.errors?
      render json: tokbox_wrapper.errors, status: :forbidden
    else
      # update the dynamo record with new status
      dynamodb_wrapper.update(primary_key: { archive_id: tokbox_recording[:id] },
                              item_updates: { status: 'stopped' })

      if dynamodb_wrapper.errors?
        render json: dynamodb_wrapper.error_messages, status: :forbidden
      else
        render json: tokbox_recording, status: :ok
      end
    end
  end

  def status_recording
    # Ask Tokbox for info about the recording
    tokbox_recording = tokbox_wrapper.get_recording(params[:session_id], params[:recording_id])

    ## If the recording is available, build the new URL
    if tokbox_recording[:status] == 'available'.freeze
      api_key = M3::Application.config.tokbox.fetch(:api_key, nil)
      relative_path = "#{api_key}/#{params[:recording_id]}/archive.mp4"

      signed_url = generate_partner_chat_signed_url(relative_path)
      tokbox_recording[:path] = signed_url
    end

    # Send tokbox recording hash to the client.
    render json: tokbox_recording, status: :ok
  end

  def video_permission
    partner_chat_permissions = PartnerChatPermissions.new(recording_path: params[:recording_path],
                                                          dynamodb_wrapper: dynamodb_wrapper,
                                                          user: current_user)

    status_code = partner_chat_permissions.status_code

    signed_url = if partner_chat_permissions.allowed_path.present?
      generate_partner_chat_signed_url(partner_chat_permissions.allowed_path)
    end

    render json: { video_url: signed_url }, status: status_code
  end

  private def tokbox_wrapper
    @tokbox_wrapper ||= VideoChat::TokBoxWrapper.new(current_user)
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

  # This method creates signed cookies using the AWS SDK and a CloudFront distribution.
  # We create three different session-cookies that allow access to the partner chat S3
  # bucket.
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-setting-signed-cookie-custom-policy.html
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-cookies.html
  # https://aws.amazon.com/premiumsupport/knowledge-center/cf-signed-cookies-s3-origin/
  private def generate_partner_chat_cookies(relative_path)
    signed_cookies = PartnerChatCookie.new(relative_url: relative_path).cookies

    # Merge signed cookies into the rails cookie jar
    signed_cookies.each { |key, properties| cookies[key] = properties }
  end

  # Generate signed URL with relative path pointing to primary S3 bucket.
  private def generate_partner_chat_signed_url(relative_path)
    PartnerChatUrl.new(relative_url: relative_path).signed_url
  end
end
