describe Instructor::ProntoController do
  describe '#show' do
    let(:program) { build_stubbed(:program) }
    let(:instructor) { build_stubbed(:instructor) }

    before do
      allow(Program).to receive(:find).and_return(program)
      allow(instructor).to receive(:has_current_access_to?).and_return(true)
      allow(controller).to receive(:current_program).and_return(program)
      fake_login(instructor)
    end

    def do_request
      get :show, params: { program_id: program.id }
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    context 'with pronto' do
      before do
        allow(@controller).to receive(:ensure_pronto_availability)
      end

      it 'should display the main reports page' do
        allow(@controller).to receive(:ensure_pronto_availability)
        do_request

        expect(response).to be_successful
        expect(response).to render_template(:show)
      end

      it 'should assign the program from the params' do
        do_request
        expect(assigns[:program]).to eq(program)
      end
    end

    context 'without pronto' do
      before do
        @program = program
        @expected_redirect = instructor_dashboard_path(program)
      end
      it_behaves_like 'an action that requires pronto availability'
    end
  end
end
