describe GradebookDropLowScoresCategorySectionUpdaterWorker do
  let(:config) { instance_double('config') }
  let(:redis_cache) { instance_double('mock_redis', del: true) }
  let(:updater) { instance_double(GradebookEngine::DropLowScoresCategorySectionLockingUpdater) }
  let(:params) do
    {
      category_id: 1,
      section_id: 2,
      max_score_action_id: 100,
      queue_time: Time.zone.now.to_s(:db),
      school_id: 107
    }
  end

  before do
    allow(M3::Application).to receive(:config).and_return(config)
    allow(config).to receive(:job_conflict_cache).and_return(redis_cache)
    allow(Sidekiq).to receive(:redis).and_return(redis_cache)
    allow(GradebookEngine::DropLowScoresCategorySectionLockingUpdater)
      .to receive(:new).and_return(updater)
    allow(updater).to receive(:find_job_and_maybe_update)
  end

  describe '#perform' do
    context 'when there is not a conflict with a Gradebok school merge' do
      before do
        allow(redis_cache).to receive(:keys)
          .with(GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY)
          .and_return([])
        dlscs_in_progress_key = format(
          GradebookDropLowScoresCategorySectionUpdaterWorker::DLSCS_IN_PROGRESS_KEY,
          category_id: params[:category_id],
          school_id: params[:school_id],
          section_id: params[:section_id]
        )
        allow(redis_cache).to receive(:set).with(dlscs_in_progress_key, true)
                                           .and_return([dlscs_in_progress_key])
      end

      it 'does not raise an error' do
        expect do
          described_class.new.perform(*params.values)
        end.not_to raise_error
      end

      it 'creates a new category section updater' do
        described_class.new.perform(*params.values)

        expected_params = params.except(:school_id).merge(
          queue_time: params[:queue_time]
        ).values

        expect(GradebookEngine::DropLowScoresCategorySectionLockingUpdater)
          .to have_received(:new)
          .with(*expected_params)
      end
    end

    context 'when there is a conflict with a Gradebok school merge' do
      before do
        allow(redis_cache).to receive(:keys)
          .with(GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY)
          .and_return([GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY])
      end

      it 'raises an error' do
        expect do
          described_class.new.perform(*params.values)
        end.to raise_error SchoolMergeJobConflictError
      end
    end
  end
end
