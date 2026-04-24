FactoryBot.define do
  factory(:ai_conversation_session, class: 'AI::ConversationSession') do |f|
    f.association :activity
    f.association :user
  end
end
