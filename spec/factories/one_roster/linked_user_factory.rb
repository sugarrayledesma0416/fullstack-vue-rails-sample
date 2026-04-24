FactoryBot.define do
  factory :one_roster_linked_user, class: OneRoster::LinkedUser do |lu|
    lu.association :user
    lu.association :school
    lu.sourced_id { SecureRandom.uuid }
    lu.sequence(:external_username) { |n| format('user_%03d', n) }
    lu.email do |proxy|
      FFaker::Internet.email("#{proxy.user.first_name} #{proxy.user.last_name}")
    end
  end
end
