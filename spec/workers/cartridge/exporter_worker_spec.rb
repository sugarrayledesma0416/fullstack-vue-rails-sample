module Cartridge
  describe ExporterWorker do
    let(:worker) { described_class.new }
    let(:program) { create(:program) }
    let(:creator) { create(:user) }
    let(:cc_version) { '1.1.0' }
    let(:exporter) do
      instance_double(Cartridge::Exporter, export: true, errors: [])
    end

    before do
      allow(Cartridge::Exporter).to receive(:new).and_return(exporter)
      allow(worker).to receive(:logger_data_merge)
    end

    it 'creates a cartridge exporter object' do
      worker.perform(program.id, creator.id, cc_version)
      expect(Cartridge::Exporter).to have_received(:new).with(
        program: program,
        creator: creator,
        cc_version: cc_version
      )
    end

    it 'exports the cartridge package' do
      worker.perform(program.id, creator.id, cc_version)
      expect(exporter).to have_received(:export)
    end

    it 'logs the process to logstash' do
      worker.perform(program.id, creator.id, cc_version)
      expect(worker).to have_received(:logger_data_merge)
        .with(
          cc_version: cc_version,
          creator_id: creator.id,
          program_id: program.id
        ).once
    end

    it 'logs error if job for same school is in process' do
      errors = ['Something went wrong']
      allow(exporter).to receive(:errors).and_return(errors)

      worker.perform(program.id, creator.id, cc_version)

      expect(worker).to have_received(:logger_data_merge)
        .with(error_key: program.id, cc_exporter_error: 'Something went wrong')
    end

    it 'logs any exporter errors to logstashs' do
      config = instance_double('config')
      redis_cache = instance_double('mock_redis')
      cc_wc_key = format(described_class::CC_IN_PROGRESS_KEY, program_id: program.id)
      allow(M3::Application).to receive(:config).and_return(config)
      allow(config).to receive(:job_conflict_cache).and_return(redis_cache)
      allow(Sidekiq).to receive(:redis).and_return(redis_cache)
      allow(redis_cache).to receive(:set).and_return(true)
      allow(redis_cache).to receive(:del).and_return(true)
      allow(redis_cache).to receive(:keys).with(cc_wc_key)
                                          .and_return([cc_wc_key])

      worker.perform(program.id, creator.id, cc_version)

      expect(worker).to have_received(:logger_data_merge)
        .with(error_key: program.id,
              cc_exporter_error: 'job is currently in process for this program')
    end
  end
end
