describe StandardAlignmentsUpdateWorker do
  describe '#perform' do
    let(:config) { instance_double('config') }
    let(:redis_cache) { instance_double('mock_redis', del: true) }
    let(:ab_error) { 'AB returned an error' }
    let(:os_error) { 'OpenSearch returned 500 error' }
    let(:logger) { instance_double(Sidekiq::Logger) }
    let(:helper) { instance_double(StandardsMapping::StandardsMappingIndicesHelper, errors: []) }
    let(:alignments_processor) { instance_double(StandardsMapping::AlignmentsProcessor, errors: [], obsolete_alignments: []) }
    let(:program_id) { 1234 }
    let(:update_worker) { StandardAlignmentsUpdateWorker.new }

    before do
      allow(StandardsMapping::AlignmentsProcessor).to receive(:new).and_return(alignments_processor)
      allow(alignments_processor).to receive(:import_new_assets)
      allow(alignments_processor).to receive(:import_updated_alignments).with(program_id)
      allow(alignments_processor).to receive(:sync_asset_alignments)
      allow(StandardsMapping::StandardsMappingIndicesHelper).to receive(:new)
        .with(true).and_return(helper)
      allow(helper).to receive(:upload_standard_assets)
        .with(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)
      allow(helper).to receive(:upload_standard_alignments)
        .with(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)
      allow(Sidekiq).to receive(:logger).and_return(logger)
      allow(logger).to receive(:error)
      allow(logger).to receive(:warn)

      # stub worker instance methods to control conflict behavior and updates
      allow_any_instance_of(StandardAlignmentsUpdateWorker).to receive(:no_prior_process_running?).and_return(true)
      allow_any_instance_of(StandardAlignmentsUpdateWorker).to receive(:update_alignments).and_return([])
    end

    context 'when pulling StandardAlignments from AB does not return an error' do
      it 'does not log any error' do
        update_worker.perform({ "program_id" => program_id })
        expect(logger).not_to have_received(:error)
      end
    end

    context 'when pulling StandardAlignments from AB returns an error' do
      it 'logs the error' do
        allow_any_instance_of(StandardAlignmentsUpdateWorker).to receive(:update_alignments).and_return([ab_error])
        update_worker.perform({ "program_id" => program_id })
        expect(logger).to have_received(:error).with(a_string_including("had failures: AB returned an error"))
      end
    end

    context 'when uploading StandardAlignments does not return an error' do
      it 'does not log any error' do
        update_worker.perform({ "program_id" => program_id })
        expect(logger).not_to have_received(:error)
      end
    end

    context 'when uploading Standard alignments returns an error' do
      it 'logs the error' do
        # simulate upload errors by returning them from update_alignments
        allow_any_instance_of(StandardAlignmentsUpdateWorker).to receive(:update_alignments).and_return([os_error])
        update_worker.perform({ "program_id" => program_id })
        expect(logger).to have_received(:error).with(a_string_including('OpenSearch returned 500 error'))
      end
    end

    context 'when there is no conflicting StandardAlignmentsUpdateWorker job' do
      it 'does not log a warning' do
        update_worker.perform({ "program_id" => program_id })
        expect(logger).not_to have_received(:warn)
      end
    end

    context 'when there is a conflicting StandardAlignmentsUpdateWorker job' do
      before do
        allow_any_instance_of(StandardAlignmentsUpdateWorker).to receive(:no_prior_process_running?).and_return(false)
      end

      it 'does not attempt to perform updates and logs a warning' do
        update_worker.perform({ "program_id" => program_id })
        expect(logger).to have_received(:warn)
      end
    end
  end
end
