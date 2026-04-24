require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe ProgramConfigVersionsController do
  let(:creator) { create(:user) }
  let(:program) { create(:program) }
  let(:first_setting_value) { 'first_url' }
  let(:second_setting_value) { 'second_url' }
  let(:user) { create(:user) }

  describe 'GET /index' do
    before do
      Timecop.travel(1.day.ago) do
        ProgramConfig.create!(
          program_id: program.id,
          creator_id: creator.id,
          vtext: { 'url' => first_setting_value }
        )
      end
      ProgramConfig.create!(
        program_id: program.id,
        creator_id: creator.id,
        vtext: { 'url' => second_setting_value }
      )
    end

    def do_request
      get(program_config_versions_path(program.id))
    end

    include_examples 'require logged in user'

    it 'redirects a user who is not a program config manager' do
      log_in_user(user)
      do_request

      expect(response).to redirect_to '/403'
    end

    it 'displays all the config versions to a program config manager' do
      user.roles.create!(name: Role::PROGRAM_CONFIG_MANAGER)

      log_in_user(user)
      do_request

      expect(response.body).to include(first_setting_value)
      expect(response.body).to include(second_setting_value)
    end
  end
end
