describe GradebookDropLowScoresSchedulerWorker do
  let(:config) { instance_double('config') }
  let(:redis_cache) { instance_double('mock_redis') }
  let(:scheduler) { instance_double('GradebookEngine::DropLowScoresScheduler') }

  before do
    allow(M3::Application).to receive(:config).and_return(config)
    allow(config).to receive(:job_conflict_cache).and_return(redis_cache)
    allow(Sidekiq).to receive(:redis).and_return(redis_cache)
    allow(GradebookEngine::DropLowScoresScheduler).to receive(:new).and_return(scheduler)
    allow(scheduler).to receive(:enqueue_jobs)
  end

  describe '#perform' do
    it 'does not conflict with Gradebook school merge' do
      allow(redis_cache).to receive(:keys).with(GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY)
                                         .and_return([])
      allow(redis_cache).to receive(:set).with(GradebookDropLowScoresSchedulerWorker::DLS_IN_PROGRESS_KEY, true)
                                         .and_return([GradebookDropLowScoresSchedulerWorker::DLS_IN_PROGRESS_KEY])
      allow(redis_cache).to receive(:del).and_return(true)
      worker = described_class.new
      allow(worker).to receive(:no_prior_process_running?).and_return(true)
      worker.perform
    end

    it 'raises error due to conflict with Gradebook school merge' do
      allow(redis_cache).to receive(:keys).with(GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY)
                                         .and_return([GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY])
      allow(redis_cache).to receive(:del).and_return(true)
      expect { described_class.new.perform }.to raise_error SchoolMergeJobConflictError
    end
  end
end
