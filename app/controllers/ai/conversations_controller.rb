module AI
  class ConversationsController < ApplicationController
    before_action :require_user

    def session_response
      response = create_conversation_session_response
      serializer = AI::ConversationSessionMessageSerializer.new(response.message)
      render json: { message: serializer.serializable_hash }
    rescue StandardError => e
      log_response_failure(e)
      raise e
    end

    def saved_messages
      conversation_session = ConversationSession.find(params[:id])
      if valid_session_ownership?(conversation_session)
        render_messages(conversation_session.saved_messages)
      else
        render json: { messages: [], error: 'not-authorized' }, status: :unauthorized
      end
    end

    def update_messages
      conversation_session = ConversationSession.find(params[:id])
      if conversation_session.user_id == current_user.id
        update_conversation_session_messages(conversation_session)
        render_messages(conversation_session.saved_messages)
      else
        render json: { error: 'not-authorized' }, status: :unauthorized
      end
    end

    def restart_session
      conversation_session = ConversationSession.find(params[:id])
      if conversation_session.user_id == current_user.id
        conversation_session.restart
        render json: {}
      else
        render json: { error: 'not-authorized' }, status: :unauthorized
      end
    end

    private def authorized_instructor?(conversation_session)
      current_user.instructor? && (
        conversation_session.attempt_id &&
        gradeable_section?(conversation_session.section_id)
      )
    end

    private def create_conversation_session_response
      ConversationSessionResponse.create(
        session_id: params[:id],
        user_message_attrs: safe_response_create_params
      )
    end

    private def log_response_failure(error)
      conversation_session = ConversationSession.find(params[:id])
      conversation_session.log_response_failure(error)
    end

    private def gradeable_section?(section_id)
      current_user.section_can_be_graded?(section_id)
    end

    private def render_messages(messages)
      render(
        json: messages,
        root: 'messages',
        each_serializer: AI::ConversationSessionMessageSerializer
      )
    end

    private def safe_response_create_params
      params.require(:message).permit(
        :guid,
        :message_text
      ).to_h.symbolize_keys
    end

    private def update_conversation_session_messages(conversation_session)
      return if params[:messages].blank?

      messages_params = params.permit(
        messages: %i[guid audio_file_path message_text role]
      )
      AI::ConversationSessionMessagesUpdater.new(
        session: conversation_session,
        messages_attrs: messages_params[:messages]
      ).update
    end

    private def valid_session_ownership?(conversation_session)
      conversation_session.user_id == current_user.id ||
      authorized_instructor?(conversation_session)
    end
  end
end
