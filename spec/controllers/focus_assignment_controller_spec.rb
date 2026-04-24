describe ApplicationController do
  # We're creating a vanilla Controller so that we can
  # isolate the before_actions we want to test
  controller do
    include FocusAssignment

    before_action :set_current_program
    before_action :set_current_focus

    def show
      head :ok
    end
  end

  before do
    @program = build_stubbed(:program)
    allow(Program).to receive(:find_by_id).and_return(@program)
  end

  it 'sets up the instance variables we need' do
    get :show, params: { program_id: '1', id: '2' }
    expect(assigns(:program)).to eq(@program)
    expect(assigns(:current_focus)).to be_a(Focus)
  end
end
