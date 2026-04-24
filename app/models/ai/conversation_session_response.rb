module AI
  class ConversationSessionResponse
    attr_accessor :session_id, :message, :user_message_attrs

    def initialize(session_id:, user_message_attrs:)
      self.session_id = session_id
      self.user_message_attrs = user_message_attrs
    end

    def self.create(**kwargs)
      new(**kwargs).tap(&:do_request)
    end

    def do_request
      self.message = session.get_response(**user_message_attrs)
    end

    private def session
      @session ||= ConversationSession.find(session_id)
    end
  end
end
