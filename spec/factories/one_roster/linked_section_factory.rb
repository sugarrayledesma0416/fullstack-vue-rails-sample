FactoryBot.define do
  factory :one_roster_linked_section, class: OneRoster::LinkedSection do |ls|
    ls.association :section
    ls.class_external_id { SecureRandom.uuid }
    ls.course_external_id { SecureRandom.uuid }
  end
end
