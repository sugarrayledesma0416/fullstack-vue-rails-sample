require 'rails_helper'

describe SidekiqMonitorController do
  let(:user) { create(:user).tap { |user| user.roles << Role.create!(name: Role::DEVELOPER) } }

  before do
    fake_login(user)
  end

  describe '#sidekiq_redirect' do
    it 'redirects to the Sidekiq Monitor web interface' do
      get :sidekiq_redirect

      expect(response).to redirect_to('/sidekiq')
    end
  end
end
