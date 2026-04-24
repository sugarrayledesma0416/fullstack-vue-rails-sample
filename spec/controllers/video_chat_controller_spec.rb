describe VideoChatController do
  let(:tokbox_wrapper) { instance_double(VideoChat::TokBoxWrapper) }
  let(:url_signer) { instance_double(PartnerChatUrl) }
  let(:student) { build_stubbed(:student) }

  before do
    fake_login(student)

    allow(VideoChat::TokBoxWrapper).to receive(:new).and_return(tokbox_wrapper)
    allow(PartnerChatUrl).to receive(:new).and_return(url_signer)
  end

  describe '#status_recording' do
    let(:archive_id) { 'abc123' }
    let(:relative_signed_url) { "123456/#{archive_id}/archive.mp4" }
    let(:signed_url) { "#{Rails.configuration.partner_chat_cdn}/#{relative_signed_url}" }

    let(:tokbox_response) do
      # When using S3 archiving with TokBox, we always receive a nil url and
      # the name 'archive.mp4'.
      {
        data: {
          name: 'archive.mp4',
          url: nil
        },
        id: archive_id,
        status: 'available'
      }
    end

    before do
      allow(tokbox_wrapper).to receive(:get_recording).and_return(tokbox_response)
      allow(url_signer).to receive(:signed_url).and_return(signed_url)
    end

    context 'when a recording has been uploaded to our primary bucket' do
      it 'returns a json object with a signed URL' do
        post :status_recording, params: { session_id: 'session_id', recording_id: archive_id }

        object = JSON.parse(response.body)

        expect(url_signer).to have_received(:signed_url)
        expect(object['path']).to eq(signed_url)
      end
    end

    context 'when a recording is not available for playback' do
      before do
        tokbox_response[:status] = 'stopped'
      end

      it 'sends the status to the client' do
        post :status_recording, params: { session_id: 'session_id', recording_id: archive_id }

        object = JSON.parse(response.body)
        expect(object['status']).to eq 'stopped'
      end

      it 'does not try to generate a signed URL' do
        post :status_recording, params: { session_id: 'session_id', recording_id: archive_id }

        object = JSON.parse(response.body)
        expect(object['path']).to be_nil
      end
    end
  end
end
