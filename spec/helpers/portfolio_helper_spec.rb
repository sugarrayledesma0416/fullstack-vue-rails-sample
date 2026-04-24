describe PortfolioHelper do
  describe '#embed_remote_image' do
    it 'returns base 64 encoded image data' do
      img_url = 'http://example.com/file.jpg'
      uri_instance = instance_double(URI::HTTP)
      stream = instance_double(StringIO)
      allow(stream).to receive(:read).and_return('some-data')
      allow(URI).to receive(:parse).with(img_url).and_return(uri_instance)
      allow(uri_instance).to receive(:open).and_return(stream)

      expect(helper.embed_remote_image(img_url)).to eq 'data:image/jpeg;base64,c29tZS1kYXRh'
    end
  end
end
