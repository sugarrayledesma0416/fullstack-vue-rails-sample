describe StandardsUpdateWorker do
  describe '#perform' do
    let(:ab_error) { 'AB returned an error' }
    let(:os_error) { 'OpenSearch returned 500 error' }
    let(:logger) { instance_double(Sidekiq::Logger) }
    let(:helper) { instance_double(StandardsMapping::StandardsMappingIndicesHelper, errors: []) }
    let(:standards_processor) { instance_double(StandardsMapping::StandardsProcessor, errors: []) }
    let(:config) { instance_double('config') }
    let(:redis_cache) { instance_double('mock_redis') }

    before do
      # need to add a standard that will trigger the code
      # that updates the searchable flag
      create(:standard, number: '', label: '')
      allow(StandardsMapping::StandardsProcessor).to receive(:new).and_return(standards_processor)
      allow(standards_processor).to receive(:save_process)
      allow(StandardsMapping::StandardsMappingIndicesHelper).to receive(:new)
                                                                  .with(true).and_return(helper)
      allow(helper).to receive(:upload_standards)
                         .with(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)
      allow(Sidekiq).to receive(:logger).and_return(logger)
      allow(logger).to receive(:error)
      allow(M3::Application).to receive(:config).and_return(config)
      allow(config).to receive(:job_conflict_cache).and_return(redis_cache)
      allow(Sidekiq).to receive(:redis).and_return(redis_cache)
      allow(redis_cache).to receive(:keys).with(StandardsUpdateWorker::STDS_UPDATE_IN_PROGRESS_KEY)
                                          .and_return([])
      allow(redis_cache).to receive(:set).with(StandardsUpdateWorker::STDS_UPDATE_IN_PROGRESS_KEY,
                                               true)
                                         .and_return(true)
      allow(redis_cache).to receive(:del).and_return(true)
    end

    context 'when pulling Standards from AB does not return an error' do
      it 'does not log any error' do
        StandardsUpdateWorker.new.perform
        expect(logger).not_to have_received(:error)
      end
    end

    context 'when pulling Standards from AB returns an error' do
      it 'logs the error' do
        allow(standards_processor).to receive(:errors).and_return([ab_error])
        StandardsUpdateWorker.new.perform
        expect(logger).to have_received(:error).with('Pulling standards from AB had failures: AB returned an error')
      end
    end

    context 'when uploading Standards does not return an error' do
      it 'does not log any error' do
        StandardsUpdateWorker.new.perform
        expect(logger).not_to have_received(:error)
      end
    end

    context 'when uploading Standards returns an error' do
      it 'logs the error' do
        allow(helper).to receive(:errors).and_return([os_error])
        StandardsUpdateWorker.new.perform
        expect(logger).to have_received(:error).with('Updating standards in OpenSearch failed with error: OpenSearch returned 500 error')
      end
    end

    context 'when there is a conflict with a prior running worker' do
      it 'does not run the job' do
        allow(redis_cache).to receive(:keys).with(StandardsUpdateWorker::STDS_UPDATE_IN_PROGRESS_KEY)
                                            .and_return([StandardsUpdateWorker::STDS_UPDATE_IN_PROGRESS_KEY])
        expect(redis_cache).not_to have_received(:set).with(StandardsUpdateWorker::STDS_UPDATE_IN_PROGRESS_KEY,
                                                 true)
      end
    end
  end
end
