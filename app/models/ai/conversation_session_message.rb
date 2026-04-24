module AI
  class ConversationSessionMessage < ApplicationRecord
    self.table_name = 'ai_virtual_chat_session_messages'

    VALID_ROLES = %w[assistant system user].freeze

    belongs_to(
      :session,
      class_name: 'AI::ConversationSession',
      inverse_of: :messages
    )
    has_one(
      :chat_feedback_flag,
      class_name: 'AI::ChatFeedbackFlag',
      dependent: :destroy,
      foreign_key: :ai_virtual_chat_session_messages_id
    )

    validates :role, inclusion: VALID_ROLES
    validates :guid, presence: true
    serialize :ai_api_response

    def system_message?
      role == 'system'
    end

    def assistant_message?
      role == 'assistant'
    end

    def user_message?
      role == 'user'
    end

    def status
      content && content['status']
    end

    def on_topic
      content && content['on_topic']
    end

    private def content
      return if ai_api_response.blank?

      @content ||= JSON.parse(ai_api_response['content'])
    end
  end
end
