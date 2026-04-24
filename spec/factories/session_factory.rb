FactoryBot.define do
  factory :persistent_session , class: :Session do
    session_id { SecureRandom.hex(10) }
    created_at { Time.now }
    association :user, factory: :user
  end

  factory :expired_persistent_session, parent: :persistent_session do
    created_at { 8.days.ago }
    updated_at { 8.days.ago }
  end
end
