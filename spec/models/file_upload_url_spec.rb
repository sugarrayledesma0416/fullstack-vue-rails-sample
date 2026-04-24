describe FileUploadUrl do
  let(:file_upload_url_instance) { described_class.new(relative_url: relative_url) }
  let(:relative_url) { 'file-upload/file.doc' }

  let(:signed_url) { 'signed_url' }
  let(:cloudfront_signer) do
    instance_double(Aws::CloudFront::UrlSigner, signed_url: signed_url)
  end

  before do
    mock_bucket = 'test.files.vhlcentral.dom'
    allow(Radner).to receive(:bucket_name).and_return(mock_bucket)
    allow(Aws::CloudFront::UrlSigner).to receive(:new).and_return(cloudfront_signer)
  end

  describe '#full_url' do
    it 'returns the complete url in radner bucket for the given file' do
      expected_url = "https://#{Radner.bucket_name}/#{relative_url}"
      expect(file_upload_url_instance.full_url).to eq expected_url
    end
  end

  describe '#signed_url' do
    it 'returns a cloudfront signed url' do
      expect(file_upload_url_instance.signed_url).to eq signed_url
    end

    it 'passes a specific policy to the signer' do
      Timecop.freeze(Time.zone.now) do
        file_upload_url_instance.signed_url
        expect(cloudfront_signer).to have_received(:signed_url).with(
          file_upload_url_instance.full_url,
          expires: 10.minutes.from_now
        )
      end
    end
  end
end
