FactoryBot.define do
  factory :group_chat_recording do
    association :user, factory: :student
    association :activity, factory: :group_chat_activity
    participants { [] }
    recording_path { 'bs/group/chat/path' }
    token { 'MyString' }
  end
end
