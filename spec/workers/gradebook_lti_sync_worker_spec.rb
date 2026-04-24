describe GradebookLtiSyncWorker do
  let(:worker) { described_class.new }
  let(:gradebook_syncer) do
    instance_double(GradebookEngine::Lti::MultiContextLinkSyncer, sync_all: true)
  end

  before do
    allow(GradebookEngine::Lti::MultiContextLinkSyncer)
      .to receive(:new).and_return(gradebook_syncer)
  end

  it 'creates a syncer class and initiates a syncing process' do
    worker.perform
    expect(gradebook_syncer).to have_received(:sync_all)
  end

  it 'aborts if another job with the same name is running' do
    allow(worker).to receive(:no_prior_process_running?).and_return(false)

    worker.perform

    expect(gradebook_syncer).not_to have_received(:sync_all)
  end
end
