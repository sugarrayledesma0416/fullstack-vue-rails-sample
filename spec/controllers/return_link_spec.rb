describe ReturnLink, type: :controller do
  controller(ApplicationController) do
    include ReturnLink

    def new
      assign_return_link
      head :ok
    end

    def index
      set_return_info('Return to Foo') do
        'some/custom/path'
      end
      head :ok
    end
  end

  let(:default_path) { 'http/:/foo/bar' }
  let(:user) { build_stubbed(:student) }

  before do
    allow(BestDefaultPath).to receive(:best_default_path).and_return(default_path)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#assign_return_link' do
    def do_request(params = {})
      get :new, params: params
    end

    context 'when there is no return link stored in the session,' do
      before do
        session[:activity_return] = nil
      end

      it 'finds and assigns the best path for the current user, program, and section' do
        program = build_stubbed(:program)
        allow(controller).to receive(:current_program).and_return(program)
        section = build_stubbed(:section)
        allow(controller).to receive(:current_section).and_return(section)
        do_request
        expect(BestDefaultPath).to have_received(:best_default_path)
          .with(user, program, section, session)
        expect(assigns(:return_url)).to eq(default_path)
      end

      it 'sets a return label of go to dashboard' do
        allow(BestDefaultPath).to receive(:best_default_path)
        do_request
        expect(assigns(:return_label)).to eq('Go to Dashboard')
      end
    end

    context 'when there is a return link stored in the session,' do
      before do
        session[:activity_return] = { 'label' => 'valid_label', 'url' => 'valid_url' }
      end

      it 'assigns the label of the return link in the session to return_label' do
        do_request
        expect(assigns(:return_label)).to eql 'valid_label'
      end

      context 'when no return_to param exists,' do
        it 'assigns the url of the return link in the session to return_url' do
          do_request
          expect(assigns(:return_url)).to eql 'valid_url'
        end
      end

      context 'when there is a return_to param,' do
        it 'it assigns the return_to param to return_url' do
          do_request(return_to: 'return_to_url')
          expect(assigns(:return_url)).to eql 'return_to_url'
        end

        it 'it stores the return_to param in the session' do
          do_request(return_to: 'new_return_to_url')
          expect(session[:activity_return]['url']).to eql 'new_return_to_url'
        end

        context 'when there is a start_strand param,' do
          it 'appends the start_strand param to the return_url' do
            do_request(return_to: 'return_to_url', start_strand: 'valid_strand')
            expect(assigns(:return_url)).to eql 'return_to_url?start_strand=valid_strand'
          end
        end

        context 'when there is no start_strand param,' do
          it 'does not include a start_strand param in the return_url' do
            do_request(return_to: 'return_to_url')
            expect(assigns(:return_url)).not_to include '&start_strand'
          end
        end

        context 'when there is a start_topic param,' do
          it 'appends the start_topic param to the return_url' do
            do_request(return_to: 'return_to_url', start_topic: 'valid_topic')
            expect(assigns(:return_url)).to eql 'return_to_url?start_topic=valid_topic'
          end
        end

        context 'when there is a display_lesson param,' do
          it 'appends the display_lesson param to the return_url' do
            do_request(
              return_to: 'return_to_url',
              start_topic: 'valid_topic',
              display_lesson: '2'
            )
            expect(assigns(:return_url)).to eq(
              'return_to_url?start_topic=valid_topic&display_lesson=2'
            )
          end
        end

        context 'when there is a toc_location param,' do
          it 'appends the toc_location param to the return_url' do
            do_request(
              return_to: 'return_to_url',
              start_topic: 'valid_topic',
              toc_location: '2'
            )
            expect(assigns(:return_url)).to eq(
              'return_to_url?start_topic=valid_topic&toc_location=2'
            )
          end
        end

        context 'when there is no start_topic param,' do
          it 'does not include a start_topic param in the return_url' do
            do_request(return_to: 'return_to_url')
            expect(assigns(:return_url)).not_to include '&start_topic'
          end
        end
      end
    end
  end

  describe '#set_return_info' do
    it 'sets the correct return values in session' do
      get :index
      expect(session[:activity_return]).to eq(
        'label' => 'Return to Foo',
        'url' => 'some/custom/path'
      )
    end
  end
end
