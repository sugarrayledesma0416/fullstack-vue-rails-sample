describe Media::MediaItemUploadsController do
  describe '#create' do
    let(:params) { { 'abc' => '123' } }
    let(:uploader) { double(MediaItemUploader) }
    let(:result) { { woo: :hoo } }

    before do
      allow(MediaItemUploader).to receive(:new).and_return(uploader)
      allow(uploader).to receive(:upload).and_return(uploader)
      allow(uploader).to receive(:result).and_return(result)
    end

    def do_request(other_params = {})
      post :create, params: params.merge(other_params)
    end

    it 'initializes a new MediaItemUploader specifying params, and calls upload on it' do
      expect(MediaItemUploader).to receive(:new).with(hash_including(params)).and_return(uploader)
      expect(uploader).to receive(:upload)
      do_request
    end

    it 'renders text containing the result of the MediaItemUploader as json' do
      do_request
      expect(response.body).to eq(result.to_json)
    end
  end
end
