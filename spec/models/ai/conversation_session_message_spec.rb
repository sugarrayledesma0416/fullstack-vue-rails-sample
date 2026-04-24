describe AI::ConversationSessionMessage do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:guid) }

    it do
      is_expected.to validate_inclusion_of(:role).in_array(
        %w[user system assistant]
      )
    end
  end

  describe '#status' do
    let(:message) { build(:ai_conversation_session_message) }

    it 'returns nil if the ai_api_response is blank' do
      expect(message.status).to be_nil
    end

    it 'returns the status property of the ai_api_response content if ' \
       'the ai_api_response is set' do
      content = { 'status' => 'complete' }
      message.ai_api_response = { 'content' => content.to_json }

      expect(message.status).to eq('complete')
    end
  end

  describe '#on_topic' do
    let(:message) { build(:ai_conversation_session_message) }

    it 'returns nil if the ai_api_response is blank' do
      expect(message.on_topic).to be_nil
    end

    it 'returns the on_topic property of the ai_api_response ' \
       'content if the ai_api_response is set' do
      content = { 'on_topic' => false }
      message.ai_api_response = { 'content' => content.to_json }

      expect(message.on_topic).to be(false)
    end
  end
end
