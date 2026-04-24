describe Policy::Course::ControllerMethods, type: :controller do
  controller do
    include Policy::Course::ControllerMethods

    before_action :require_course_policy_permission

    def index
      render plain: 'woohaah'
    end
  end

  let(:best_path) { '/best_default_path' }
  let(:policy) { double(Policy::Course::CreateEdit) }
  let(:school) { create(:school) }

  before do
    allow(BestDefaultPath).to receive(:best_default_path) { best_path }
    allow(controller).to receive(:course_create_edit_policy) { policy }
    allow(policy).to receive(:permit?).and_return(true)
  end

  it "raises an error if the controller doesn't implement selected_school_id" do
    expect { get :index, params: { school_id: 99 } }.to raise_error(NotImplementedError)
  end

  context 'with a valid selected_school_id method' do
    before do
      allow(controller).to receive(:selected_school_id) { school.id }
    end

    it 'checks if the user has permission to manage courses at the school ' \
    'specified by the selected_school_id method' do

      expect(policy).to receive(:permit?).with(school)
      get :index, params: { school_id: school.id }
    end

    it 'redirects the user to best default path if they are not authorized' do
      allow(policy).to receive(:permit?).and_return(false)

      get :index
      expect(response).to redirect_to(best_path)
    end

    it 'does not redirect the user if they are authorized' do
      get :index
      expect(response).not_to redirect_to(best_path)
    end
  end
end
