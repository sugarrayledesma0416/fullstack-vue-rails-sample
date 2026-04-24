module AI
  class ChatOverallFeedback < ApplicationRecord
    self.table_name = 'ai_chat_overall_feedbacks'

    belongs_to :program
    belongs_to :activity
    belongs_to(
      :session,
      class_name: 'AI::ConversationSession',
      foreign_key: :ai_virtual_chat_sessions_id
    )
    belongs_to :graded_by, class_name: 'Instructor'
    validates :comment, presence: true
  end
end
