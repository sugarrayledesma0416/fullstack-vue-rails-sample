describe FileUploader do
  let(:original_filename) { 'my_file_is_awesome.txt' }
  let(:uuid_param) { 'uu-i-am-an-id' }
  let(:uploaded_path) { '/some/fake/path' }
  let(:file_contents) { 'ABCDE' }
  let(:fake_file) do
    instance_double(
      'RackUploadedFile',
      path: uploaded_path,
      original_filename: original_filename,
      size: 12_345,
      read: file_contents
    )
  end
  let(:params) { { qquuid: uuid_param, qqfile: fake_file } }
  let(:expected_tmp_path) { File.join('tmp', 'uploads', "#{uuid_param}.tmp").to_s }
  let(:s3_bucket) { instance_double(Radner::S3Storage, store_file_contents!: nil) }

  before do
    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
    allow(FileUtils).to receive(:move)
  end

  describe '#validate' do
    it 'contains an error message when the uploaded file size is 0' do
      allow(fake_file).to receive(:size).and_return(0)
      uploader = described_class.new(params)
      uploader.validate
      expect(uploader.errors).to include 'Your file has no size'
    end

    it 'contains an error message when the uploaded file size is greater than 50mb' do
      allow(fake_file).to receive(:size).and_return(52_428_801)
      uploader = described_class.new(params)
      uploader.validate
      expect(uploader.errors).to include 'File is too large, maximum file size is 50 MB.'
    end

    it 'contains an error message when the path is blank' do
      allow(fake_file).to receive(:path).and_return(' ')
      uploader = described_class.new(params)
      uploader.validate
      expect(uploader.errors).to include 'The path to your file could not be found'
    end

    it 'contains an error message when the original filename is blank' do
      allow(fake_file).to receive(:original_filename).and_return(' .txt')
      uploader = described_class.new(params)
      uploader.validate
      expect(uploader.errors).to include "Your file's name is blank"
    end

    it 'contains an error message when the original filename has incorrect extension' do
      allow(fake_file).to receive(:original_filename).and_return('my_file_is_awesome.img')
      uploader = described_class.new(params)
      uploader.validate
      expect(uploader.errors[0]).to include 'File has invalid extension'
    end
  end
end
