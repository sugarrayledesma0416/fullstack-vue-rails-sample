describe MediaItemsController do
  describe 'GET show' do
    before do
      @media_item = double(MediaItem, media_type: 'audio', filename: 'filename')
      allow(MediaItem).to receive(:find).with('37').and_return(@media_item)
      get :show, params: { id: '37' }
    end

    it 'assigns the requested media item' do
      expect(assigns(:media_item)).to eq(@media_item)
    end

    it "doesn't display the application layout" do
      expect(response).to render_template(:show, layout: nil)
    end
  end

  describe 'GET svg_content' do
    let(:svg_content) { '<test>svg_content</test>' }
    let(:svg_media) do
      build_stubbed(:media_item_image, id: '192207', filename: 'test.svg')
    end

    let(:user) { create(:user) }

    before do
      allow(MediaItem).to receive(:find).and_call_original
      allow(MediaItem).to receive(:find).with(svg_media.id.to_s).and_return(svg_media)
      allow(svg_media).to receive(:svg_content).and_return(svg_content)
    end

    def do_request(params)
      fake_login(user)
      get :svg_content, params: params
    end

    it 'requires a valid user' do
      get :svg_content, params: { id: svg_media.id }

      expect(response).to have_http_status(:redirect)
    end

    it 'returns xml' do
      do_request(id: svg_media.id)

      expect(response.body).to eq(svg_content)
    end

    it 'returns 404 if not found' do
      do_request(id: 123)

      expect(response.status).to eq(404)
      expect(response.body).to eq('<error>Media Not Found</error>')
    end

    it 'returns 500 if an unexpected error occurs' do
      allow(MediaItem).to receive(:find).and_raise('Something went wrong')
      expect(VHLMonitor).to receive(:notify)
      do_request(id: svg_media.id)

      expect(response.status).to eq(500)
    end
  end
end
