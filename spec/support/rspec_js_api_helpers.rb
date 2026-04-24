module RspecJsApiHelpers
  def initialize_client_calls_for_user(user)
    # initial stubbing of client calls with empty results
    allow(Maestro::User).to receive(:redeemed_passcodes).with(user.guid).and_return([])
    allow(Maestro::UserLicense).to receive(:all_for_user).with(user.guid).and_return([])
    allow(Maestro::User).to receive(:accessible_programs).with(user.guid).and_return([])
    allow(Maestro::ApiToken).to receive(:fetch).and_return(double(Maestro::ApiToken, :secret => 'secret', jid: 'foo@bar.com'))
  end

  def initialize_program_access_client_calls_for_user_and_program(user, program, include_vtext = false)
    initialize_client_calls_for_user(user)

    allow(Maestro::User).to receive(:accessible_programs).with(user.guid).and_return([program])
    licenses = [create_user_license]
    licenses.append(create_vtext_user_license) if include_vtext

    allow(Maestro::UserLicense).to receive(:all_for_user).with(user.guid).and_return(licenses)
    allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return(licenses)
    allow(Maestro::UserLicense).to receive(:all_for_users_in_program).and_return(licenses)
    allow(Maestro::School).to receive(:grace_period_allocation).and_return({'number_used' => 0, 'number_allowed' => 0})
    allow(Maestro::SiteLicense).to receive(:find_by_program_and_school_or_district)
      .and_return(instance_double(Maestro::SiteLicense, response: nil))
  end

  alias :initialize_program_access_client_calls_for_instructor :initialize_program_access_client_calls_for_user_and_program

  def give_instructor_access_to_toc(params = {})
    course_licenses ||= []
    allow(Maestro::LicenseGroup).to receive(:all).and_return([ double('LicenseGroup', :id => 1, :name => '01-Supersite') ])
    course_licenses << Maestro::CourseLicense.new({ 'license_group' => { 'id' => 1, 'demo' => false } })
    allow(Maestro::CoursePackage).to receive(:all).and_return([])
    allow(Maestro::CoursePackage).to receive(:all_for_courses).and_return([])
    allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)
    allow(Maestro::UserLicense).to receive(:all_for_user_and_program).with([], program.id).and_return([])
    allow(Maestro::UserLicense).to receive(:all_for_users_in_program).with([], program.id).and_return([])
    current_activity = params[:activity] || activity #use activity defined by 'let' statements if none specified
    current_activity.update!(license_group_id: course_licenses.first.license_group.id)
  end

  def give_user_access_to_program(user, program, include_vtext = false)
    initialize_client_calls_for_user(user)
    licenses = [create_user_license]
    licenses.append(create_vtext_user_license) if include_vtext

    allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([])
    allow(Maestro::UserLicense).to receive(:all_for_user_and_program).with(user.guid, program.id).and_return(licenses)
    allow(Maestro::UserLicense).to receive(:all_for_user).with(user.guid).and_return(licenses)
    license_content = {:license_group_ids => licenses.map { |license| license['license_group']['id'] }, :lessons => '*'}
    return_val = Maestro::LicensedContent.new(JSON.parse(license_content.to_json))
    allow(Maestro::LicensedContent).to receive(:find_for_user_and_program).with(user.guid, program.id).and_return(return_val)
    allow(Maestro::User).to receive(:accessible_programs).with(user.guid).and_return([program])
  end

  def create_user_license(params = {})
    license_params = params[:license_params] || { 'license_group' => { 'id' => 1, 'name' => 'Practice', 'includes_content' => true, 'demo' => false }, 'expiration_date' => 1.year.from_now.to_date.to_s }
    user_license = Maestro::UserLicense.new(license_params)
    allow(user_license).to receive(:expired?).and_return(params[:has_expired] || false)
    allow(user_license).to receive(:practice_app?).and_return(params[:is_practice_app] || true)
    allow(user_license).to receive(:grace_period?).and_return(params[:has_grace_period] || false)
    user_license
  end

  def create_vtext_user_license
    vtext_license_params = {
      'license_group' =>
        {
          'id' => 2,
          'name' => 'vText',
          'site_function_name' => 'vtext',
          'includes_content' => false,
          'demo' => false
        },
      'expiration_date' => 1.year.from_now.to_date.to_s
    }
    create_user_license(license_params: vtext_license_params)
  end

  def initialize_client_calls_for_user(user)
    # initial stubbing of client calls with empty results
    allow(Maestro::User).to receive(:redeemed_passcodes).with(user.guid).and_return([])
    allow(Maestro::UserLicense).to receive(:all_for_user).with(user.guid).and_return([])
    allow(Maestro::User).to receive(:accessible_programs).with(user.guid).and_return([])
    allow(Maestro::ApiToken).to receive(:fetch).and_return(double(Maestro::ApiToken, secret: 'secret', jid: 'foo@bar.com'))
  end
end
