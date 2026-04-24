FactoryBot.define do
  factory(:ai_conversation_session_message, class: 'AI::ConversationSessionMessage') do |f|
    f.association :session, factory: :ai_conversation_session
    f.guid { SecureRandom.uuid }
    f.role { 'user' }
    f.message_text { 'Good morning.' }
  end
end
