module AI
  class ConversationSession < ApplicationRecord
    self.table_name = 'ai_virtual_chat_sessions'

    DEFAULT_EXPECTED_RESPONSE_COUNT = 3

    FAILURE_REASON_MESSAGE = <<~MESSAGE.freeze
      The student was unable to complete the activity because a
      non-recoverable technical error occurred. Any responses
      generated before the error occured are shown below.
    MESSAGE

    # optional: true is needed for activity preview, where the m3 activity does not exist
    belongs_to :activity, optional: true
    belongs_to :user
    # optional: true is needed because practice attempts are not persisted
    # but a persisted session object is still necessary in practice mode.
    belongs_to :attempt, optional: true
    has_many(
      :messages,
      dependent: :destroy,
      inverse_of: :session,
      class_name: 'AI::ConversationSessionMessage',
      foreign_key: :session_id
    )
    has_one(
      :overall_feedback,
      class_name: 'AI::ChatOverallFeedback',
      foreign_key: :ai_virtual_chat_sessions_id
    )

    delegate :section_id, to: :attempt

    def self.create_preview(preview_activity, user)
      message_text = preview_activity.content_object.question.initial_prompt
      preview_system_prompt = preview_activity.content_object.question.system_prompt
      create!(
        activity: nil,
        user:,
        preview_system_prompt:
      ).tap do |session|
        # Create the initial prompt message
        AI::ConversationSessionMessage.create!(
          guid: SecureRandom.uuid,
          message_text:,
          role: 'assistant',
          session:
        )
      end
    end

    def find_or_create_message(guid:, role:, message_text:, audio_file_path: nil)
      message = messages.find_by(guid:)
      return message if message.present?

      begin
        ConversationSessionMessage.create!(
          audio_file_path:,
          guid:,
          message_text:,
          role:,
          session: self
        )
      rescue ActiveRecord::RecordNotUnique
        # The record didn't exist and we failed to create it because of a
        # uniqueness index. This can happen if another process created the
        # message before us. If we can find the message now, we'll update it,
        # otherwise, it's an error.
        ConversationSessionMessage.find_by!(
          guid:,
          session: self
        )
      end
    end

    def create_initial_message
      return if messages.present?

      # Create the initial prompt message
      ConversationSessionMessage.create!(
        guid: SecureRandom.uuid,
        message_text: question.initial_prompt,
        role: 'assistant',
        session: self
      )
    end


    # If messages exist, create new client chat populated with
    # existing messages.
    # If not, generate new client chat with initial system and user messages.
    # Add specified message to client chat, get response, and log specified
    # message and response in messages.
    def get_response(guid:, message_text:)
      find_or_create_message(
        guid:,
        message_text:,
        role: 'user'
      )

      begin
        virtual_chat_response = client.chat(
          parameters: {
            messages: ai_messages,
            model: VHL::AI::Constants::Models::OpenAI::DEFAULT_CHAT,
            response_format:,
            temperature: 0.6
          },
          response_schema_type: VHL::AI::Constants::ResponseSchemas::VIRTUAL_CHAT,

          span_attributes: {
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => user&.id,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => id,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'ai_virtual_chat',
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_VERSION => VHL::AI::Core::VERSION
          }
        )

        content = JSON.parse(virtual_chat_response.to_api_hash['content'])
        content['status'] = conversation_status(content)

        ai_api_response = virtual_chat_response.to_api_hash
        ai_api_response['content'] = content.to_json

        message = ConversationSessionMessage.create!(
          ai_api_response: ai_api_response,
          guid: SecureRandom.uuid,
          message_text: virtual_chat_response.partner_response,
          role: 'assistant',
          session: self
        )
        message
      rescue VHL::AI::Core::SchemaError => e
        log_response_failure(e)
        nil
      rescue StandardError => e
        log_response_failure(e)
        nil
      end
    end

    def log_response_failure(error)
      if error.is_a?(StandardError)
        VHLMonitor.notify(error)
        update!(completion_failure_reason: FAILURE_REASON_MESSAGE)
      else
        update!(completion_failure_reason: error)
      end
    end

    def restart
      messages_to_destroy = saved_messages.to_a[1..]
      return if messages_to_destroy.empty?

      files_to_delete = messages_to_destroy.filter_map(&:audio_file_path)
      messages_to_destroy.each(&:destroy)

      if files_to_delete.present?
        ConversationMessageDeleterWorker.perform_async(files_to_delete)
      end
    end

    def saved_messages
      messages.order(:created_at)
    end

    def serialized_saved_messages
      saved_messages.map do |message|
        AI::ConversationSessionMessageSerializer.new(message).serializable_hash
      end
    end

    private def ai_messages
      ([system_message, references_message] + saved_messages).map do |message|
        {
          'role' => message.role,
          'content' => message.message_text
        }
      end
    end

    private def client
      @client ||= VHL::AI::Core::Client.new
    end

    private def preview?
      preview_system_prompt.present?
    end

    private def system_message
      @system_message ||= ConversationSessionMessage.new(
        message_text: preview? ? preview_system_prompt : question.system_prompt,
        role: 'system',
        session: nil
      )
    end

    private def references_message
      if @references_message.present?
        return @references_message
      end

      # Use the formatter to generate the references message
      references_xml = AI::ActivityReferencesFormatter.new(activity).format_as_xml
      references_xml = '<references></references>' if references_xml.nil?

      # Create the references message
      @references_message = ConversationSessionMessage.new(
        message_text: references_xml,
        role: 'assistant',
        session: nil
      )
    end

    private def question
      @question ||= activity.content_object.question
    end

    private def response_format
      VHL::AI::Schemas::OpenAI::Request::ResponseFormats::VIRTUAL_CHAT
    end

    # Returns true if the conversation is completed, false otherwise.
    # Calculate this here rather than rely on the AI's arithmetic.
    private def conversation_status(current_content)
      expected_response_count = current_content['expected_response_count'] || DEFAULT_EXPECTED_RESPONSE_COUNT
      on_topic_count = 0

      if current_content['on_topic'] == true
        on_topic_count += 1
      end

      saved_messages.each do |message|
        next unless message.ai_api_response.present?

        begin
          content = JSON.parse(message.ai_api_response['content'])
          if content['on_topic'] == true
            on_topic_count += 1
          end
        rescue JSON::ParserError
          # Skip messages with invalid JSON in ai_api_response
          next
        end
      end

      if on_topic_count >= expected_response_count
        'complete'
      else
        'incomplete'
      end
    end
  end
end
