module AI
  class ConversationMessageDeleterWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(audio_paths)
      return if Lossless::Client.new.delete_virtual_chat_recordings(
        audio_paths
      )

      raise StandardError, 'Failed to delete lossless recordings'
    end
  end
end
