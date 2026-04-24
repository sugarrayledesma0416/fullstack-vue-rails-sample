require 'tasks/lti_launches_cleaner'

describe LtiLaunchesCleaner do
  describe '#clean' do
    let(:cleaner) { described_class.new(batch_size: 1) }

    it 'destroys LTI launches older than 1 month' do
      create(:lti_launch, created_at: 5.weeks.ago)

      expect do
        cleaner.clean
      end.to change(Lti::Launch, :count).by(-1)
    end

    it 'does not destroy LTI launches younger than 1 month' do
      create(:lti_launch, created_at: 2.weeks.ago)

      expect do
        cleaner.clean
      end.not_to change(Lti::Launch, :count)
    end

    it 'yields after each batch when a block is given' do
      create(:lti_launch, created_at: 5.weeks.ago)

      expect do |block|
        cleaner.clean(&block)
      end.to yield_with_no_args
    end
  end
end
