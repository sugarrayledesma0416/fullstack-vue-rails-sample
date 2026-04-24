module AI
  class ConversationSessionMessageSerializer < ActiveModel::Serializer
    attributes :guid, :role, :message_text, :audio_file_path, :status, :on_topic
  end
end
