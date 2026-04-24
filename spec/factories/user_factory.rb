FactoryBot.define do
  factory :user do
    first_name {generate(:first_name)}
    last_name  {generate(:last_name)}
    sequence(:username) {|n| "user_" + ("%03d" % n)}
    email {|proxy|"#{proxy.username}@vistahigherlearning.com"}
    year_of_birth { 2010 }
    first_dashboard_viewed_at { 30.days.ago }
    last_login_at { 3.days.ago }
    registration_window_open { true }
    fake { false }
    gender { 'Male' }
    crypted_password { 'mxyzptlk' }
    password_salt { 'NaCl' }
    persistence_token { 'foo' }
    single_access_token { 'foo' }
    perishable_token { 'foo' }
    sequence(:guid) { |_n| SecureRandom.uuid }
  end

  factory :student, parent: :user, class: 'Student' do
    account_type { 'Student' }
    first_name {generate(:first_name)}
    last_name  {generate(:last_name)}
    email {|proxy| FFaker::Internet.email("#{proxy.first_name} #{proxy.last_name}") }
  end

  factory :clever_student, parent: :student do
    email { |proxy| "#{proxy.username}@#{User::CLEVER_USERS_FAKE_EMAIL_DOMAIN}" }
  end

  factory :one_roster_user, parent: :user do |user|
    user.email do
      "#{SecureRandom.uuid}@#{User::ONE_ROSTER_USERS_FAKE_EMAIL_DOMAIN}"
    end
    user.username { "ra_#{SecureRandom.uuid}" }
  end

  factory :one_roster_student, parent: :student do |student|
    student.email do
      "#{SecureRandom.uuid}@#{User::ONE_ROSTER_USERS_FAKE_EMAIL_DOMAIN}"
    end
    student.username { "ra_#{SecureRandom.uuid}" }
  end

  factory :one_roster_instructor, parent: :instructor do |instructor|
    instructor.email do
      "#{SecureRandom.uuid}@#{User::ONE_ROSTER_USERS_FAKE_EMAIL_DOMAIN}"
    end
    instructor.username { "ra_#{SecureRandom.uuid}" }
  end

  factory :one_roster_student_with_school, parent: :one_roster_student do
    after(:create) do |user|
      user.schools << create(:one_roster_school)
    end
  end

  factory :lti_rostering_user, parent: :user do |user|
    username { "lti_user_#{SecureRandom.uuid}" }
    email do |proxy|
      "#{proxy.username}@#{User::LTI_USERS_FAKE_EMAIL_DOMAIN}"
    end
  end

  factory :lti_rostering_instructor, parent: :instructor do |user|
    username { "lti_user_#{SecureRandom.uuid}" }
    email do |proxy|
      "#{proxy.username}@#{User::LTI_USERS_FAKE_EMAIL_DOMAIN}"
    end
  end

  factory :lti_rostering_student, parent: :student do |user|
    username { "lti_user_#{SecureRandom.uuid}" }
    email do |proxy|
      "#{proxy.username}@#{User::LTI_USERS_FAKE_EMAIL_DOMAIN}"
    end
  end

  factory :fake_student, parent: :student do
    fake { true }
  end

  factory :instructor, parent: :user, class: 'Instructor' do
    account_type { 'Instructor' }
    first_name {generate(:first_name)}
    last_name  {generate(:last_name)}
    email {|proxy| FFaker::Internet.email("#{proxy.first_name} #{proxy.last_name}") }
  end

  factory :institution_admin, parent: :instructor, class: 'InstitutionAdmin' do
    account_type { 'InstitutionAdmin' }
  end

  factory :data_admin, parent: :instructor, class: 'DataAdmin' do |u|
    u.account_type { 'DataAdmin' }
  end

  factory :clever_instructor, parent: :instructor do
    email { |proxy| "#{proxy.username}@#{User::CLEVER_USERS_FAKE_EMAIL_DOMAIN}" }
  end

  factory :clever_admin, parent: :instructor do
    email { |proxy| "#{proxy.username}@#{User::CLEVER_ADMIN_USERS_FAKE_EMAIL_DOMAIN}" }
  end

  factory :editor, parent: :user, class: 'Editor' do
    account_type { 'Editor' }
  end

  factory :grader, parent: :user, class: 'Grader' do
    account_type { 'Grader' }
  end

  factory :admin, parent: :user, class: 'Student' do
    account_type { 'Admin' }
    username { 'admin' }
    email { 'admin@vistahigherlearning.com' }
  end

  factory :cartridge_user, parent: :user do |user|
    user.username { "cartridge_user_#{SecureRandom.uuid}" }
    user.email do
      "#{username}@#{User::CARTRIDGE_USERS_FAKE_EMAIL_DOMAIN}"
    end
  end

  factory :cartridge_student, parent: :student do |student|
    student.username { "cartridge_user_#{SecureRandom.uuid}" }
    student.email do
      "#{username}@#{User::CARTRIDGE_USERS_FAKE_EMAIL_DOMAIN}"
    end
  end

  factory :cartridge_instructor, parent: :instructor do |instructor|
    instructor.username { "cartridge_user_#{SecureRandom.uuid}" }
    instructor.email do
      "#{username}@#{User::CARTRIDGE_USERS_FAKE_EMAIL_DOMAIN}"
    end
  end

  factory :support_rep_user, parent: :user do
    username { 'support_rep' }

    after(:create) do |user|
      create(:support_rep_role, users: [user])
      create(:common_cartridge_creator_role, users: [user])
    end
  end

  factory :program_config_manager, parent: :user do
    username { 'program_config_manager' }

    after(:create) do |user|
      create(:program_config_manager_role, users: [user])
    end
  end

  factory :resource_editor_user, parent: :user do
    username { 'resource_editor_user' }

    after(:create) do |user|
      create(:resource_editor_role, users: [user])
    end
  end

  sequence :first_name do |_index|
    # rails 2.3.17 quick fix: apostrophe make some cukes fail
    # randomly
    "D'#{FFaker::Name.first_name}"
  end

  sequence :last_name do |_index|
    # rails 2.3.17 quick fix: apostrophe make some cukes fail
    # randomly
    "O'#{FFaker::Name.last_name}"
  end
end
