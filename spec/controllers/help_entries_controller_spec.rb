describe HelpEntriesController do
  let(:help_entry) { build_stubbed(:help_entry, page: 'home#front', url: 'http://example.com') }

  def login_authorized_user
    @user = build_stubbed(:user)
    allow(@user).to receive(:roles).and_return([double(Role, name: 'customer_service')])
    fake_login(@user)
  end

  describe '#index' do
    it_should_require_a_logged_in_user { get('index') }

    it 'sorts help entries by page' do
      expect(HelpEntry).to receive(:order).with('page ASC')

      login_authorized_user
      get :index
    end

    it 'assigns help entries' do
      help_entries = [build_stubbed(:help_entry), build_stubbed(:help_entry)]
      allow(HelpEntry).to receive(:order).and_return(help_entries)

      login_authorized_user
      get :index
      expect(assigns(:help_entries)).to eql help_entries
    end
  end

  describe '#new' do
    it_should_require_a_logged_in_user { get('new') }
  end

  describe '#create' do
    before do
      allow(help_entry).to receive(:save).and_return(true)
      login_authorized_user
      allow(HelpEntry).to receive(:new).and_return(help_entry)
    end

    context 'on success' do
      it 'assigns the help entry' do
        post :create, params: { help_entry: { page: help_entry.page, url: help_entry.url } }
        expect(assigns(:help_entry)).to eql help_entry
      end

      it 'redirects to index' do
        post :create, params: { help_entry: { page: help_entry.page, url: help_entry.url } }
        expect(response).to redirect_to help_entries_path
      end

      it 'sets a flash success messsage' do
        post :create, params: { help_entry: { page: help_entry.page, url: help_entry.url } }
        expect(flash[:notice]).not_to be_nil
      end
    end

    context 'on failure' do
      before do
        allow(help_entry).to receive(:save).and_return(false)
      end

      it 'renders the new view' do
        post :create, params: { help_entry: { page: help_entry.page, url: help_entry.url } }
        expect(response).to render_template 'help_entries/new'
      end

      it 'sets a flash error' do
        allow(controller.instance_eval { flash }).to receive(:sweep)
        post :create, params: { help_entry: { page: help_entry.page, url: help_entry.url } }
        expect(flash[:error]).not_to be_nil
      end
    end
  end

  describe '#edit' do
    before do
      login_authorized_user
      allow(HelpEntry).to receive(:find).with('1').and_return(help_entry)
    end

    it 'assigns the requested help entry' do
      get :edit, params: { id: '1' }
      expect(assigns(:help_entry)).to eql help_entry
    end
  end

  describe '#update' do
    before do
      login_authorized_user
      allow(HelpEntry).to receive(:find).with('1').and_return(help_entry)
    end

    context 'on success' do
      before do
        @help_entry_attributes = { page: 'home#front', url: 'http://support.vhlcentral.com/page.html' }
        allow(help_entry).to receive(:update).and_return(true)
        allow(HelpEntry).to receive(:find).with('1').and_return(help_entry)
      end

      it 'assigns the help entry' do
        put :update, params: { id: '1', help_entry: @help_entry_attributes }
        expect(assigns(:help_entry)).to eql help_entry
      end

      it 'updates the requested help entry' do
        expect(help_entry).to receive(:update)
        put :update, params: { id: '1', help_entry: @help_entry_attributes }
      end

      it 'redirects to the index' do
        put :update, params: { id: '1' }
        expect(response).to redirect_to help_entries_path
      end

      it 'sets a flash success message' do
        put :update, params: { id: '1' }
        expect(flash[:notice]).not_to be_nil
      end
    end

    context 'on failure' do
      before do
        allow(help_entry).to receive(:update).and_return(false)
        allow(controller.instance_eval { flash }).to receive(:sweep)
        put :update, params: { id: '1' }
      end

      it 'renders the edit page' do
        expect(response).to render_template 'help_entries/edit'
      end

      it 'sets a flash error' do
        expect(flash[:error]).not_to be_nil
      end
    end
  end

  describe '#destroy' do
    context 'on success' do
      before do
        login_authorized_user
        allow(help_entry).to receive(:destroy).and_return(true)
        allow(HelpEntry).to receive(:find).with('1').and_return(help_entry)
      end

      it 'destroys the help entry' do
        expect(help_entry).to receive(:destroy).and_return(true)
        delete :destroy, params: { id: '1' }
      end

      it 'sets the flash' do
        delete :destroy, params: { id: '1' }
        expect(flash[:notice]).not_to be_nil
        expect(flash[:error]).to be_nil
      end

      it 'redirects to the index' do
        delete :destroy, params: { id: '1' }
        expect(response).to redirect_to help_entries_path
      end
    end

    context 'on failure' do
      before do
        login_authorized_user
        expect(help_entry).to receive(:destroy).and_return(false)
        allow(HelpEntry).to receive(:find).with('1').and_return(help_entry)
      end

      it 'sets the flash' do
        delete :destroy, params: { id: '1' }
        expect(flash[:notice]).to be_nil
        expect(flash[:error]).not_to be_nil
      end

      it 'renders the index' do
        delete :destroy, params: { id: '1' }
        expect(response).to redirect_to help_entries_path
      end
    end
  end
end
