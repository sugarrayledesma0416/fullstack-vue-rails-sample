FactoryBot.define do
  factory :ai_chat_feedback_flag, class: 'AI::ChatFeedbackFlag' do
    comment { "This is a feedback comment" }
    message_guid { "msg_#{SecureRandom.hex(8)}" }
    graded_by_id { create(:instructor).id }

    program
    activity

    association :conversation_session_message,
                factory: :ai_conversation_session_message

    association :suggestion_rating_category,
                factory: :ai_suggestion_rating_category

    trait :with_specific_guid do
      message_guid { "specific_guid_123" }
    end

    trait :without_comment do
      comment { nil }
    end
  end
end
