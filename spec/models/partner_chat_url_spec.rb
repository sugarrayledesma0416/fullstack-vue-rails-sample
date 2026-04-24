describe PartnerChatUrl do
  let(:pchat_url_instance) { described_class.new(relative_url: relative_url) }
  let(:relative_url) { 'recording/file.mp4' }
  let(:pchat_cdn) { 'https://partner_recordings.example.com' }
  let(:signed_url) { 'signed_url' }
  let(:cloudfront_signer) do
    instance_double(Aws::CloudFront::UrlSigner, signed_url: signed_url)
  end

  before do
    allow(Rails.configuration).to receive(:partner_chat_cdn).and_return(pchat_cdn)
    allow(Aws::CloudFront::UrlSigner).to receive(:new).and_return(cloudfront_signer)
  end

  describe '#full_url' do
    it 'returns the complete url in the pchat bucket for the given file' do
      expected_url = "#{Rails.configuration.partner_chat_cdn}/#{relative_url}"
      expect(pchat_url_instance.full_url).to eq expected_url
    end
  end

  describe '#signed_url' do
    it 'returns an cloudfront signed url' do
      expect(pchat_url_instance.signed_url).to eq signed_url
    end

    it 'passes a specific policy to the signer' do
      Timecop.freeze(Time.zone.now) do
        pchat_url_instance.signed_url
        expect(cloudfront_signer).to have_received(:signed_url).with(
          pchat_url_instance.full_url,
          policy: {
            'Statement' => [
              'Resource' => pchat_url_instance.full_url,
              'Condition' => {
                'DateLessThan' => { 'AWS:EpochTime' => (Time.zone.now + 10.minutes).to_i }
              }
            ]
          }.to_json
        )
      end
    end
  end
end
