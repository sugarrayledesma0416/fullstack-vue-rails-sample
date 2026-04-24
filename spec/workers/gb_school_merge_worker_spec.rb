describe GbSchoolMergeWorker do
  let(:old_school)      { build_stubbed(:school) }
  let(:new_school)      { build_stubbed(:school) }
  let(:valid_params) { ['old_school_id' => old_school.id, 'new_school_id' => new_school.id] }
  let(:config) { instance_double('config') }
  let(:redis_cache) { instance_double('mock_redis') }
  let (:dlscs_wc_key) { GradebookDropLowScoresCategorySectionUpdaterWorker::DLSCS_IN_PROGRESS_WILDCARD_KEY % old_school.id }

  before do
    allow(M3::Application).to receive(:config).and_return(config)
    allow(config).to receive(:job_conflict_cache).and_return(redis_cache)
    allow(Sidekiq).to receive(:redis).and_return(redis_cache)
    allow(GradebookEngine::GradebookAPI).to receive(:change_schools).and_return(true)
  end

  describe '#perform' do
    it 'processes the GradebookBook SchoolMerge' do
      allow(redis_cache).to receive(:keys).with(StudentWorkTransferWorker::SWT_IN_PROGRESS_KEY)
                                         .and_return([])
      allow(redis_cache).to receive(:keys).with(GradebookDropLowScoresSchedulerWorker::DLS_IN_PROGRESS_KEY)
                                         .and_return([])
      allow(redis_cache).to receive(:keys).with(dlscs_wc_key)
                                .and_return([])
      allow(redis_cache).to receive(:set).with(GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY, true)
                                         .and_return(true)
      allow(redis_cache).to receive(:del).and_return(true)
      described_class.new.perform(*valid_params)
      expect(GradebookEngine::GradebookAPI).to have_received(:change_schools).with(any_args)
    end

    it 'raises error due to conflict with StudentWorkTransfer' do
      allow(redis_cache).to receive(:keys).with(StudentWorkTransferWorker::SWT_IN_PROGRESS_KEY)
                                         .and_return([StudentWorkTransferWorker::SWT_IN_PROGRESS_KEY])
      allow(redis_cache).to receive(:keys).with(GradebookDropLowScoresSchedulerWorker::DLS_IN_PROGRESS_KEY)
                                         .and_return([])
      allow(redis_cache).to receive(:keys).with(dlscs_wc_key)
                                .and_return([])
      allow(redis_cache).to receive(:del).and_return(true)
      expect { described_class.new.perform(*valid_params) }.to raise_error SchoolMergeJobConflictError
      expect(GradebookEngine::GradebookAPI).not_to have_received(:change_schools)
    end

    it 'raises error due to conflict with GradebookDropLowScoresSchedulerWorker' do
      allow(redis_cache).to receive(:keys).with(StudentWorkTransferWorker::SWT_IN_PROGRESS_KEY)
                                         .and_return([])
      allow(redis_cache).to receive(:keys).with(GradebookDropLowScoresSchedulerWorker::DLS_IN_PROGRESS_KEY)
                                         .and_return([GradebookDropLowScoresSchedulerWorker::DLS_IN_PROGRESS_KEY])
      allow(redis_cache).to receive(:keys).with(dlscs_wc_key)
                                .and_return([])
      allow(redis_cache).to receive(:del).and_return(true)
      expect { described_class.new.perform(*valid_params) }.to raise_error SchoolMergeJobConflictError
      expect(GradebookEngine::GradebookAPI).not_to have_received(:change_schools)
    end

    it 'raises error due to conflict with GradebookDropLowScoresCategorySectionUpdaterWorker' do
      allow(redis_cache).to receive(:keys).with(StudentWorkTransferWorker::SWT_IN_PROGRESS_KEY)
                                .and_return([])
      allow(redis_cache).to receive(:keys).with(GradebookDropLowScoresSchedulerWorker::DLS_IN_PROGRESS_KEY)
                                .and_return([])
      allow(redis_cache).to receive(:keys).with(dlscs_wc_key)
                                .and_return([dlscs_wc_key])
      allow(redis_cache).to receive(:del).and_return(true)
      expect { described_class.new.perform(*valid_params) }.to raise_error SchoolMergeJobConflictError
      expect(GradebookEngine::GradebookAPI).not_to have_received(:change_schools)
    end
  end
end
