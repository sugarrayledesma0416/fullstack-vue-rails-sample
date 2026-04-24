require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Cartridge::Support::ExporterController do
  let(:program) { create(:program) }
  let(:user) { create(:user) }

  before do
    allow(Aws::CF::Signer).to receive(:sign_url)
  end

  describe 'GET /index' do
    def target_path
      cartridge_support_program_exporter_path(program_id: program.id)
    end

    def do_request(params = {})
      get target_path, params: params
    end

    include_examples 'require logged in user'

    context 'with a logged-in user with no CC creator role,' do
      before do
        log_in_user_with_access_to_programs(user, [program])
      end

      it 'redirects to the UA home page' do
        do_request

        expect(response).to redirect_to(ua_home_path)
      end
    end

    context 'with a logged-in user with the CC creator role,' do
      before do
        user.roles.create!(name: Role::COMMON_CARTRIDGE_CREATOR)
        log_in_user_with_access_to_programs(user, [program])
      end

      it 'renders the index view' do
        do_request

        expect(response).to be_ok
        expect(response).to render_template(:index)
        expect(assigns(:search)).to be_a(Cartridge::CartridgeSearcher)
        expect(assigns(:search).program).to eq(program)
      end
    end
  end

  describe 'GET /export' do
    def target_path
      cartridge_support_program_exporter_export_path(program_id: program.id)
    end

    def do_request(params = {})
      get target_path, params: params
    end

    include_examples 'require logged in user'

    context 'with a logged-in user with no CC creator role,' do
      before do
        log_in_user_with_access_to_programs(user, [program])
      end

      it 'redirects to the UA home page' do
        do_request

        expect(response).to redirect_to(ua_home_path)
      end
    end

    context 'with a logged-in user with the CC creator role,' do
      before do
        user.roles.create!(name: Role::COMMON_CARTRIDGE_CREATOR)
        log_in_user_with_access_to_programs(user, [program])
      end

      context 'when no cartrige version is selected,' do
        it 'redirects to the exporter page' do
          do_request(cc_version: '')

          expect(response).to redirect_to(
            cartridge_support_program_exporter_path(program_id: program.id)
          )
        end
      end

      context 'when a cartridge version is selected,' do
        it 'queues a worker for the creation of the cartridge file' do
          allow(Cartridge::ExporterWorker).to receive(:perform_async)

          do_request(cc_version: '1.1.0')

          expect(response).to redirect_to(
            cartridge_support_program_exporter_path(program)
          )
          expect(flash[:notice]).to eq(
            "The common cartridge export for #{program.title} " \
            'version 1.1.0 has been scheduled.'
          )

          expect(Cartridge::ExporterWorker).to have_received(:perform_async).with(
            program.id, user.id, '1.1.0'
          )
        end
      end
    end
  end
end
