module AI
  class ConversationSessionMessagesUpdater
    attr_reader :messages_attrs, :session

    def initialize(session:, messages_attrs:)
      @session = session
      @messages_attrs = messages_attrs
    end

    def update
      messages_attrs.each do |attrs|
        message = session.find_or_create_message(
          audio_file_path: attrs[:audio_file_path],
          guid: attrs[:guid],
          message_text: attrs[:message_text],
          role: attrs[:role]
        )
        if message.audio_file_path.blank? && attrs[:audio_file_path].present?
          message.update!(audio_file_path: attrs[:audio_file_path])
        end
      end
    end
  end
end
