require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Cartridge::Support::ProgramsController do
  let(:program_1) { create(:program) }
  let(:program_2) { create(:program) }
  let(:user) { create(:user) }

  describe 'GET /index' do
    def target_path
      cartridge_support_programs_path
    end

    def do_request(params = {})
      get target_path, params: params
    end

    before do
      allow(Maestro::PackageContent).to receive(:with_common_cartridge).and_return(
        [
          instance_double(Maestro::PackageContent, program_id: program_1.id),
          instance_double(Maestro::PackageContent, program_id: program_2.id)
        ]
      )
    end

    include_examples 'require logged in user'

    context 'with a logged-in user with no CC creator role,' do
      before do
        log_in_user_with_access_to_programs(user, [program_1, program_2])
      end

      it 'redirects to the UA home page' do
        do_request

        expect(response).to redirect_to(ua_home_path)
      end
    end

    context 'with a logged-in user with the CC creator role,' do
      before do
        user.roles.create!(name: Role::COMMON_CARTRIDGE_CREATOR)
        log_in_user_with_access_to_programs(user, [program_1, program_2])
      end

      it 'renders the index view' do
        do_request

        expect(response).to be_ok
        expect(assigns(:programs)).to contain_exactly(
          program_1, program_2
        )
        expect(response).to render_template(:index)
      end
    end
  end
end
