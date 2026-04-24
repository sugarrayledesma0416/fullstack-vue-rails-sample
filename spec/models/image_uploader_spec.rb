describe ImageUploader do
  let(:original_filename) { 'my_image.jpg' }
  let(:uuid_param) { 'uu-i-am-an-id' }
  let(:uploaded_path) { '/some/fake/path' }
  let(:fake_file) { double('RackUploadedFile', :path => uploaded_path, :original_filename => original_filename, :size => 12345) }
  let(:params) { { :qquuid => uuid_param, :qqfile => fake_file } }
  let(:valid_extensions) { ImageUploader::VALID_EXTENSIONS.join(' ') }
  let(:limit_file_size) { ImageUploader::LIMIT_FILE_SIZE }

  describe '#validate' do

    it 'contains an error message if extension is not gif, jpeg, jpg or png' do
      allow(fake_file).to receive(:original_filename).and_return("a.txt")
      uploader = ImageUploader.new(params)
      uploader.validate
      expect(uploader.errors).to include "File has invalid extension. Valid extensions are #{valid_extensions}."
    end

    it 'is valid if extensions are gif, jpeg, jpg or png' do
      %w(gif jpeg jpg png).each do |extname|
        allow(fake_file).to receive(:original_filename).and_return("foo.#{extname}")
        uploader = ImageUploader.new(params)
        uploader.validate
        expect(uploader.errors).to be_empty
      end
    end

    it 'is valid when extensions are capitalized' do
      %w(GIF JPEG JPG PNG).each do |extname|
        allow(fake_file).to receive(:original_filename).and_return("foo.#{extname}")
        uploader = ImageUploader.new(params)
        uploader.validate
        expect(uploader.errors).to be_empty
      end
    end

    it 'contains an error message if file size is greater than 50mb' do
      allow(fake_file).to receive(:size).and_return(limit_file_size + 1)
      human_file_size = ActionController::Base.helpers.number_to_human_size(limit_file_size)
      uploader = ImageUploader.new(params)
      uploader.validate
      expect(uploader.errors).to include "File is too large, maximum file size is #{human_file_size}."
    end

    it 'is valid if file size is lower than 50mb' do
      uploader = ImageUploader.new(params)
      uploader.validate
      expect(uploader.errors).to be_empty
    end

  end

end
