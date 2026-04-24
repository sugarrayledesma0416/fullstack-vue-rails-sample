require 'sidekiq/testing'

describe CompositionDraftsCleanerWorker do

  let(:cleaner) { CompositionDraftsCleanerWorker.new }

  describe "#perform" do
    let(:expired_draft_1) { build_stubbed(:expired_draft_attachment) }
    let(:expired_draft_2) { build_stubbed(:expired_draft_attachment) }

    before do
      allow(CompositionAttachment).to receive(:expired_drafts).and_return([expired_draft_1, expired_draft_2])
      allow(expired_draft_1).to receive(:destroy)
      allow(expired_draft_2).to receive(:destroy)
    end

    it "finds expired drafts" do
      expect(CompositionAttachment).to receive(:expired_drafts).and_return([expired_draft_1, expired_draft_2])
      cleaner.perform
    end

    it "deletes expired drafts" do
      expect(expired_draft_1).to receive(:destroy)
      expect(expired_draft_2).to receive(:destroy)
      cleaner.perform
    end
  end


end
