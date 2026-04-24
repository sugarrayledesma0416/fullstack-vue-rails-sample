require 'rails_helper'

describe Lti::LaunchesCleanupWorker do
  describe '.perform' do
    it 'deletes LTI launches older than 30 days ' do
      create(:lti_launch, created_at: 2.months.ago)

      expect do
        described_class.new.perform
      end.to change(Lti::Launch, :count).by(-1)
    end

    it 'does not delete LTI launches younger than 30 days' do
      create(:lti_launch, created_at: 2.weeks.ago)

      expect do
        described_class.new.perform
      end.not_to change(Lti::Launch, :count)
    end
  end
end
