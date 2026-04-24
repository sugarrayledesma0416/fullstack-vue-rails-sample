describe MediaItemUploader do
  let(:original_filename) { 'my_file_is_awesome.txt' }
  let(:uuid_param) { 'uu-i-am-an-id' }
  let(:uploaded_path) { '/some/fake/path' }
  let(:file_contents) { 'ABCDE' }
  let(:fake_file) { double('RackUploadedFile', path: uploaded_path,
                                               original_filename: original_filename,
                                               size: 12345,
                                               read: file_contents) }
  let(:params) { { qquuid: uuid_param, qqfile: fake_file } }
  let(:expected_tmp_path) { File.join('tmp', 'uploads', "#{uuid_param}.tmp").to_s }
  let(:s3_bucket) { double(Radner::S3Storage, store_file_contents!: nil) }

  before do
    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
    allow(FileUtils).to receive(:move)
  end

  describe '#upload' do
    it 'returns itself to allow method chaining' do
      uploader = MediaItemUploader.new(params)
      expect(uploader.upload).to eq(uploader)
    end

    it 'calls validate' do
      uploader = MediaItemUploader.new(params)
      expect(uploader).to receive(:validate)
      uploader.upload
    end

    context 'when the uploaded file is valid' do
      it 'copies the uploaded file to a temp path in S3 based on the specified uuid param' do
        expect(s3_bucket).to receive(:store_file_contents!).with(
          expected_tmp_path,
          file_contents,
          { content_disposition: 'attachment', content_type: '' }
        )
        MediaItemUploader.new(params).upload
      end
    end

    context 'when the uploaded file is invalid' do
      it 'does not copy the uploaded file to a temp path' do
        uploader = MediaItemUploader.new(params)
        allow(uploader).to receive(:valid?).and_return(false)
        expect(FileUtils).not_to receive(:move)
        uploader.upload
        expect(uploader).not_to be_uploaded
      end
    end

    context 'when the file is infected' do
      let(:virus_name) { 'very_bad_virus' }
      let(:infected_file_params) { { 'infected' => 'true', 'virus_name' => virus_name } }
      let(:uploader) do
        MediaItemUploader.new(ActionController::Parameters.new(params))
      end

      before { params.merge!(qqfile: infected_file_params) }

      it 'returns an error message' do
        uploader.upload

        expected_error = "Your file could not be uploaded because it seems to be infected with the virus '#{virus_name}'"
        expect(uploader.errors).to include expected_error
      end

      it 'does not validate file attributes' do
        expect(uploader).not_to receive(:validate)
        uploader.upload
      end

     it 'does not copy the uploaded file to a temp path' do
        expect(FileUtils).not_to receive(:move)
        uploader.upload
        expect(uploader).not_to be_uploaded
      end
    end

  end

  describe "#result" do
    let(:uploader) { MediaItemUploader.new(params).upload }
    let(:result) { uploader.result }

    it 'includes file path where the file was saved to' do
      expect(result[:temp_file_path]).to eq(expected_tmp_path)
    end

    it 'includes the original file name of the uploaded file' do
      expect(result[:original_filename]).to eq(original_filename)
    end

    it 'includes whether the upload was successful' do
      allow(s3_bucket).to receive(:store_file_contents!).and_return(true)
      expect(result[:success]).to be_truthy
    end

    context 'when the file has not been uploaded' do
      before do
        allow(uploader).to receive(:uploaded?).and_return(false)
      end

      it 'includes errors' do
        expect(result).to have_key(:errors)
      end
    end
  end

  describe "#validate" do

    it 'contains an error message when the uploaded file size is 0' do
      allow(fake_file).to receive(:size).and_return(0)
      uploader = MediaItemUploader.new(params)
      uploader.validate
      expect(uploader.errors).to include "Your file has no size"
    end

    it 'contains an error message when the path is blank' do
      allow(fake_file).to receive(:path).and_return(" ")
      uploader = MediaItemUploader.new(params)
      uploader.validate
      expect(uploader.errors).to include "The path to your file could not be found"
    end

    it 'contains an error message when the original filename is blank' do
      allow(fake_file).to receive(:original_filename).and_return(" .txt")
      uploader = MediaItemUploader.new(params)
      uploader.validate
      expect(uploader.errors).to include "Your file's name is blank"
    end
  end
end
