require 'rails_helper'

describe FeatureFlagsController, type: :controller do
  let(:user) { create(:user) }
  let(:developer_role) { Role.create!(name: Role::DEVELOPER) }
  let(:ai_developer_role) { Role.create!(name: Role::AI_DEVELOPER) }
  let(:developer_user) { create(:user).tap { |u| u.roles << developer_role } }
  let(:ai_developer_user) { create(:user).tap { |u| u.roles << ai_developer_role } }

  describe 'GET #index' do
    context 'when not authenticated' do
      it 'redirects to login' do
        get :index
        expect(response).to redirect_to(/login/)
      end
    end

    context 'when authenticated as regular user' do
      before { fake_login(user) }

      it 'redirects to root with alert' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('You are not authorized to view this page')
      end
    end

    context 'when authenticated as developer' do
      before { fake_login(developer_user) }

      it 'renders the index page' do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end
    end

    context 'when authenticated as ai_developer' do
      before { fake_login(ai_developer_user) }

      it 'renders the index page' do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it 'loads feature flags from config' do
        # Create the feature flags YAML file for testing
        config_path = Rails.root.join('config', 'feature_flags.yml')
        yaml_content = {
          'feature_flags' => {
            'test-flag' => {
              'description' => 'Test flag',
              'default' => true,
              'type' => 'release',
              'environments' => ['test']
            }
          }
        }.to_yaml

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(config_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(config_path).and_return(yaml_content)

        get :index
        expect(assigns(:feature_flags)).to be_an(Array)
        expect(assigns(:feature_flags).first).to include(
          :name, :description, :default, :current_status
        )
      end
    end
  end
end
