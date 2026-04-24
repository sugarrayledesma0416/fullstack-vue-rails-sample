require 'requests/login_helper_methods'

describe PhantomActivityFixerController do
  let(:user) { create(:user) }

  describe "when the logged-in user with" do
    def do_request
      get(phantom_activity_fixer_index_path)
    end

    it "phantom activity deleter role" do
      user.roles.create!(name: Role::PHANTOM_ACTIVITY_DELETER)
      log_in_user(user)
      do_request
      expect(response).to render_template(:index)
    end

    it "not have phantom activity deleter role" do
      log_in_user(user)
      do_request
      expect(response).to redirect_to('/403')
    end
  end

  describe "POST #create" do
    it "redirect to the correct action" do
      user.roles.create!(name: Role::PHANTOM_ACTIVITY_DELETER)
      log_in_user(user)
      post(phantom_activity_fixer_index_path)
      expect(response).to redirect_to(action: :index)
    end
  end
end
