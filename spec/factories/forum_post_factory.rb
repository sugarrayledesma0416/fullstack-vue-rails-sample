FactoryBot.define do
  factory :forum_post do
    sequence(:text) { |index| "Body text #{index}" }
    forum
    user
    edited_at { nil }
    deleted { false }
  end
end
