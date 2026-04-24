describe PopupRequestable, type: :controller do
  controller(ApplicationController) do
    include PopupRequestable

    def new
      @from_popup = request_from_popup?
      head :ok
    end
  end

  describe '#request_from_popup' do
    it 'returns true when popup param value equals "1"' do
      get :new, params: { popup: '1' }
      expect(assigns[:from_popup]).to be_truthy
    end

    it 'returns true when toc_location param has "popup=1"' do
      get :new, params: { toc_location: 'popup=1' }
      expect(assigns[:from_popup]).to be_truthy
    end

    it 'returns false when toc_location param has "popup=2"' do
      get :new, params: { toc_location: 'popup=2' }
      expect(assigns[:from_popup]).to be_falsey
    end

    it 'returns true when popup param value equals "true"' do
      get :new, params: { popup: 'true' }
      expect(assigns[:from_popup]).to be_truthy
    end

    it 'returns false when popup param value is different than "1" or "true"' do
      get :new, params: { popup: 'another_thing' }
      expect(assigns[:from_popup]).to be_falsey
    end
  end
end
