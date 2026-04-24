FactoryBot.define do
  factory(:cartridge_user_link, class: 'Cartridge::UserLink') do |ul|
    guid { SecureRandom.uuid }
    ul.association :school
    user { association :cartridge_user, schools: [school] }
    external_user_id { SecureRandom.uuid }
    contexts_owner { false }
  end

  factory(:cartridge_instructor_user_link, parent: :cartridge_user_link) do |ul|
    user { association :cartridge_instructor, schools: [school] }
  end

  factory(:cartridge_student_user_link, parent: :cartridge_user_link) do |ul|
    user { association :cartridge_student, schools: [school] }
  end

  factory(:cartridge_contexts_owner, class: 'Cartridge::UserLink') do |ul|
    guid { SecureRandom.uuid }
    ul.association :school
    user { association :cartridge_instructor, username: external_user_id }
    external_user_id { "cartridge_contexts_owner_#{school.guid}" }
    contexts_owner { true }
  end
end
