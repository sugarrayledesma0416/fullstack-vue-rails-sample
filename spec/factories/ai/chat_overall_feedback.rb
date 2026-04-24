FactoryBot.define do
  factory :ai_chat_overall_feedback, class: 'AI::ChatOverallFeedback' do
    comment { "This is an overall feedback comment for the chat session" }
    graded_by_id { create(:instructor).id }

    program
    activity

    association :session,
                factory: :ai_conversation_session

    trait :with_long_comment do
      comment { "This is a very detailed feedback that includes multiple observations about the chat session. " * 3 }
    end

    trait :with_minimal_comment do
      comment { "Brief feedback" }
    end

    trait :invalid do
      comment { nil }
    end
  end
end
