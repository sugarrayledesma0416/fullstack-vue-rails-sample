describe Xapi::StateDeleter, if: DynamoConfig.use_local?,
                             use_local_dynamodb: true do
  let(:user) { create(:student) }
  let(:state_id_prefix) { "#{Rails.env}_#{Socket.gethostname}_" }
  let(:state_id) { "#{state_id_prefix}#{attempt.id}" }
  let(:state_deleter) { described_class.new(attempt) }

  let!(:attempt) { create(:attempt, user: user) }

  describe '#delete' do
    context 'when an attempt exists but no activity state exists,' do
      it 'acts as a NOOP' do
        expect(state_deleter.delete).to be_nil
      end
    end

    context 'when an attempt and an activity state exist' do
      before do
        Xapi::ActivityState.new(id: state_id).save!
      end

      it 'deletes the existing activity state' do
        state_deleter.delete
        record = Xapi::ActivityState.find(id: state_id)
        expect(record).to be_nil
      end
    end
  end
end
