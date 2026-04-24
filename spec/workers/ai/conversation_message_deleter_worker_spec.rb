describe AI::ConversationMessageDeleterWorker do
  let(:audio_paths) { ['foo.wav', 'bar.wav'] }
  let(:client_class) { Lossless::Client }

  let(:client) do
    instance_double(client_class, delete_virtual_chat_recordings: true)
  end

  before do
    allow(client_class).to receive(:new).and_return(client)
  end

  describe '#perform' do
    it 'instantiates a Lossless::Client instance' do
      described_class.new.perform(audio_paths)

      expect(client_class).to have_received(:new)
    end

    it 'calls delete_virtual_chat_recordings on the client instance, ' \
       'passing the specified audio paths' do
      described_class.new.perform(audio_paths)

      expect(client).to have_received(:delete_virtual_chat_recordings).with(audio_paths)
    end
  end
end
