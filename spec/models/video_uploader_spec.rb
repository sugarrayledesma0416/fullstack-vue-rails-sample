describe VideoUploader do
  let(:original_filename) { 'my_video.mp4' }
  let(:uuid_param) { 'uu-i-am-an-id' }
  let(:uploaded_path) { '/some/fake/path' }
  let(:fake_file) do
    instance_double('RackUploadedFile',
                    path: uploaded_path,
                    original_filename: original_filename,
                    size: 12_345)
  end
  let(:params) { { qquuid: uuid_param, qqfile: fake_file } }
  let(:valid_extensions) { VideoUploader::VALID_EXTENSIONS.join(' ') }

  describe '#validate' do
    it 'contains an error message if extension is not .mp4 .m4v .m4p .mov or .wmv' do
      allow(fake_file).to receive(:original_filename).and_return('a.txt')
      uploader = described_class.new(params)
      uploader.validate
      expect(uploader.errors).to include "File has invalid extension. Valid extensions are #{valid_extensions}."
    end

    it 'is valid if extensions are .mp4 .m4v or .mov' do
      %w[mp4 m4v mov].each do |extname|
        allow(fake_file).to receive(:original_filename).and_return("foo.#{extname}")
        uploader = described_class.new(params)
        uploader.validate
        expect(uploader.errors).to be_empty
      end
    end

    it 'is valid when extensions are capitalized' do
      %w[MP4 M4V MOV].each do |extname|
        allow(fake_file).to receive(:original_filename).and_return("foo.#{extname}")
        uploader = described_class.new(params)
        uploader.validate
        expect(uploader.errors).to be_empty
      end
    end
  end
end
