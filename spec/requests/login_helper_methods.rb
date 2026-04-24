def stub_user_access_to_programs(user, programs)
  allow(Maestro::User).to receive(:accessible_programs)
    .with(user.guid)
    .and_return(programs)

  user_license = create_unexpired_user_license

  allow(Maestro::UserLicense).to receive(:all_for_user_and_program)
    .and_return([user_license])
  allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
    .and_return([user_license])
end

def log_in_user_with_access_to_programs(user, programs)
  stub_user_access_to_programs(user, programs)
  log_in_user(user)
end

def log_in_user(user)
  CASClient::Frameworks::Rails::Filter.fake(user.username)
end

def create_unexpired_user_license
  Maestro::UserLicense.new(
    'expiration_date' => 1.year.from_now.to_date.to_s,
    'license_group' => {
      'demo' => false,
      'id' => 1,
      'includes_content' => true,
      'name' => 'Practice'
    }
  )
end
