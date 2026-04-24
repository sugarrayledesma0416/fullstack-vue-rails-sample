describe ServerErrorsController do
  describe '#show' do
    let(:server_error) { double(ServerErrorReportDispatcher, dispatch: true, id: 33) }
    let(:wrapper_class) { ActionDispatch::ExceptionWrapper }
    let(:wrapper) { instance_double(wrapper_class, status_code: 500) }

    before do
      request.env['HTTP_USER_AGENT'] = 'Mozilla/4.0 (compatible; MSIE 8.0; ' \
                                       'Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727)'
      allow(ServerErrorReportDispatcher).to receive(:new).and_return(server_error)
      allow(Notifier).to receive_message_chain(:server_error_report, :deliver_now)
      allow(wrapper_class).to receive(:new).and_return(wrapper)
      Rails.application.config.consider_all_requests_local = false
    end

    after do
      Rails.application.config.consider_all_requests_local = true
    end

    context 'when a user is logged in' do
      before do
        fake_login(build_stubbed(:user))
      end

      context 'with a 500 error' do
        before do
          error = StandardError.new('bang')
          error.set_backtrace(['abc'])
          request.env['action_dispatch.exception'] = error
        end

        context 'when request format is html' do
          it 'renders with the default template' do
            get :show
            expect(response).to render_template 'music_v1/default'
          end

          it 'creates a new server error report dispatcher' do
            expect(ServerErrorReportDispatcher).to receive(:new)
            expect(server_error).to receive(:dispatch)
            get :show
          end

          it 'sends an email notification' do
            notifier = double(Notifier)
            expect(Notifier).to receive(:server_error_report)
              .with(server_error)
              .and_return(notifier)
            expect(notifier).to receive(:deliver_now)
            get :show
          end

          it 'renders the 500.html template' do
            get :show
            expect(response).to render_template '500'
            expect(response.header['Content-Type']).to include 'html'
          end
        end

        context 'when request format is not html' do
          it 'does not create a server error report' do
            expect(ServerErrorReportDispatcher).not_to receive(:new)
            expect(Notifier).not_to receive(:deliver_server_error_report)
            get :show, format: :json
            expect(response.header['Content-Type']).to include 'text/plain'
          end
        end
      end

      context 'with a 404 error' do
        let(:not_found_message) { 'Could not find that record.' }
        let(:wrapper) { instance_double(wrapper_class, status_code: 404) }

        before do
          request.env['action_dispatch.exception'] = \
            ActiveRecord::RecordNotFound.new(not_found_message)
        end

        it 'does not create a server error report' do
          expect(ServerErrorReportDispatcher).not_to receive(:new)
          get :show
        end

        context 'when request format is html' do
          it 'renders the 404.html template' do
            get :show
            expect(response).to render_template '404'
            expect(response.header['Content-Type']).to include 'html'
          end
        end

        context 'when request format is not html' do
          it 'renders text' do
            get :show, format: :json
            expect(response.header['Content-Type']).to include 'text/plain'
            expect(response.body).to eq(not_found_message)
          end
        end
      end
    end

    context 'when a user is not logged in' do
      before do
        error = StandardError.new('bang')
        error.set_backtrace(['abc'])
        request.env['action_dispatch.exception'] = error
      end

      it 'creates a new server error report' do
        expect(ServerErrorReportDispatcher).to receive(:new)
          .with(hash_including(user_id: nil))
        get :show
      end

      it 'renders with the not_logged_in template' do
        get :show
        expect(response).to render_template 'music_v1/not_logged_in'
      end
    end
  end
end
