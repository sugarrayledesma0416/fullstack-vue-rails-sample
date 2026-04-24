FactoryBot.define do
  factory :partner_chat_recording do
    user
    association :partner, factory: :user
    activity
    recording_path { 'bs/partner/chat/path' }
  end
end
