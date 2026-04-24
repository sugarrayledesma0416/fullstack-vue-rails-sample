require 'pnub/client_wrapper'
class ChatController < ApplicationController
  include CartridgeViewable

  before_action :require_user

  # used on login to m3, One time per session
  def create_session
    if current_user.pubnub_client_roster[:roster][:groups].empty?
      # If there are no courses associated to the current user, tell the proper error in
      # the response.
      render json: { error: 'The user needs at least one chat course association' }, status: 428
    else
      pnub_client_wrapper = Pnub::ClientWrapper.new(current_user, safe_params['activity_type'])
      pnub_client_wrapper.create_grants

      if pnub_client_wrapper.grants_successful?
        VhlChat::AuthCache.new(M3::Application.config.chat_auth_cache)
          .store_auth(group_membership_key,
                      pnub_client_wrapper.chat_session_data,
                      pnub_client_wrapper.grants_ttl.minutes.to_i)

        render json: pnub_client_wrapper.to_json
      else
        render json: pnub_client_wrapper.grant_responses_with_errors, status: 403
      end
    end
  end

  def group_chat_channel_authorize
    pnub_client_wrapper = Pnub::ClientWrapper.new(current_user)
    pnub_client_wrapper.create_grants(params[:group_chat_channel])

    if pnub_client_wrapper.grants_successful?
      VhlChat::AuthCache.new(M3::Application.config.chat_auth_cache)
        .store_auth(group_membership_key,
                    pnub_client_wrapper.chat_session_data,
                    pnub_client_wrapper.grants_ttl.minutes.to_i)

      render json: {
        info: params[:group_chat_channel],
        pubnub_token_info: pubnub_token_from_cache
      }, status: :ok
    else
      render json: {
        message: 'PubNub grant failed',
        error: pnub_client_wrapper.grant_responses_with_errors
      }, status: :forbidden
    end
  end

  private def safe_params
    params.permit(:section_id, :activity_type)
  end
end
