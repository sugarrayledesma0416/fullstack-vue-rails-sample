describe EbooksController do
  let(:user) { build_stubbed(:student) }
  let(:program) { build_stubbed(:program) }
  let(:section) { build_stubbed(:section) }
  let(:guardian) do
    double(AccessGuardian, has_ebook?: true,
                           has_mobile_app?: false,
                           ebook_expiration_date: 1.year.from_now.to_date)
  end

  before do
    allow(user).to receive(:has_current_access_to?).and_return(true)
    allow(controller).to receive(:current_program) { program }
    allow(controller).to receive(:current_section) { section }
    allow(controller).to receive(:current_user) { user }
    allow(controller).to receive(:access_guardian) { guardian }
    fake_login(user)
  end

  describe '#index' do
    let(:presenter) { double(EbooksPresenter) }

    before do
      allow(EbooksPresenter).to receive(:new).and_return(:presenter)
    end

    def do_request_with_section(section)
      get :index, params: { program_id: program.id.to_s, section_id: section.id.to_s }
    end

    it_should_behave_like 'a page that requires program access'
    it_should_require_a_logged_in_user { get :index, params: { program_id: program.id } }

    context 'when the current user does not have access to ebooks' do
      before do
        stub_request(:get, %r{users/\d+/programs}).to_return(status: 200,
                                                             body: '',
                                                             headers: {})
        allow(BestDefaultPath).to receive(:best_default_path).and_return('/best_default_path')
        allow(guardian).to receive(:has_ebook?).and_return(false)
      end

      it 'sets a flash error' do
        get :index, params: { program_id: program.id, section_id: section.id }

        expect(flash[:error]).to eq('You do not have access to the eBook.')
      end

      it 'redirects to the best default path' do
        expect(BestDefaultPath).to receive(:best_default_path).and_return('/best_default_path')

        get :index, params: { program_id: program.id, section_id: section.id }

        expect(response).to redirect_to('/best_default_path')
      end
    end

    context 'when the current user has access to ebooks' do
      it 'assigns a new EbooksPresenter, instantiated with current program id' do
        allow(guardian).to receive(:has_ebook?).and_return(true)
        expect(EbooksPresenter).to receive(:new).with(program.id) { presenter }

        get :index, params: { program_id: program.id, section_id: section.id }

        expect(assigns[:presenter]).to eq(presenter)
      end
    end
  end

  describe '#go_to_vitalsource' do
    let(:book_id) { 'abcdefg' }

    def do_request_with_section(section)
      get :go_to_vitalsource, params: { program_id: program.id.to_s, section_id: section.id.to_s, id: book_id }
    end

    it_should_behave_like 'a page that requires program access'

    it_should_require_a_logged_in_user do
      get :go_to_vitalsource, params: { program_id: program.id.to_s, section_id: section.id.to_s, id: book_id }
    end

    context 'when the current user does not have access to ebooks' do
      before do
        stub_request(:get, %r{users/\d+/programs}).to_return(status: 200,
                                                             body: '',
                                                             headers: {})
        allow(BestDefaultPath).to receive(:best_default_path).and_return('/best_default_path')
        allow(guardian).to receive(:has_ebook?).and_return(false)
      end

      it 'sets a flash error' do
        get :go_to_vitalsource, params: { program_id: program.id.to_s, section_id: section.id.to_s, id: book_id }

        expect(flash[:error]).to eq('You do not have access to the eBook.')
      end

      it 'redirects to the best default path' do
        expect(BestDefaultPath).to receive(:best_default_path).and_return('/best_default_path')

        get :go_to_vitalsource, params: { program_id: program.id.to_s, section_id: section.id.to_s, id: book_id }

        expect(response).to redirect_to('/best_default_path')
      end
    end

    context 'when the current user has access to ebooks' do
      let(:expires) { 1.year.from_now.to_date }

      before do
        allow(guardian).to receive(:has_ebook?).and_return(true)
        allow(guardian).to receive(:ebook_expiration_date) { expires }
      end

      it 'requests a vitalsource sso url, passing in user, book_id, and' \
         'ebook expiration date' do
        expect(Vitalsource).to receive(:request_sso_url)
          .with(user, book_id, program.id, expires)
          .and_return('/valid/sso/url')

        get :go_to_vitalsource, params: { program_id: program.id.to_s, section_id: section.id.to_s, id: book_id }
      end

      context 'when the Vitalsource api response is a string' do
        it 'redirects to that string' do
          vitalsource_url = 'https://some.vitalsource.sso/url'
          allow(Vitalsource).to receive(:request_sso_url)
            .and_return(vitalsource_url)

          get :go_to_vitalsource, params: { program_id: program.id.to_s, section_id: section.id.to_s, id: book_id }

          expect(response).to redirect_to(vitalsource_url)
        end
      end

      context 'when the Vistalsource api response is a hash' do
        let(:error_code) { '403' }
        let(:error_response) { { error_code: error_code } }
        before do
          allow(Vitalsource).to receive(:request_sso_url)
            .and_return(error_response)
          allow(VHLMonitor).to receive(:error)
          get :go_to_vitalsource, params: { program_id: program.id.to_s, section_id: section.id.to_s, id: book_id }
        end

        it 'sets a flash error containing the flash error' do
          expect(flash[:error]).to include(error_code)
        end

        it 'redirects to the ebooks#index action' do
          expect(response).to redirect_to(ebooks_path(program.id, section.id))
        end

        it 'sends a notification to the exception monitoring service' do
          expect(VHLMonitor).to have_received(:error).with(
            'Vitalsource Bookshelf API error',
            response: error_response
          )
        end
      end
    end
  end
end
