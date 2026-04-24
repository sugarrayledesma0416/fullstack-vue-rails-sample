describe Instructor::CreatedActivitiesHelper do
  include described_class

  describe '#activity_title' do
    it 'returns a heading including the type of activity' do
      expect(activity_title('partner_chat')).to eq('<div>Create new Partner Chat activity</div>')
    end
  end
end
