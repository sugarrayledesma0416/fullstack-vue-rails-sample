module AI
  class ChatFeedbackFlag < ApplicationRecord
    self.table_name = 'ai_chat_feedback_flags'

    belongs_to :program
    belongs_to :activity
    belongs_to(
      :conversation_session_message,
      class_name: 'AI::ConversationSessionMessage',
      foreign_key: :ai_virtual_chat_session_messages_id
    )
    belongs_to(
      :suggestion_rating_category,
      class_name: 'AI::SuggestionRatingCategory',
      foreign_key: :ai_suggestion_rating_categories_id
    )
  end
end
