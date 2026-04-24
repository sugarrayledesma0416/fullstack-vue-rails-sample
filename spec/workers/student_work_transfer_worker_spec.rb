describe StudentWorkTransferWorker do
  let(:student)      { build_stubbed(:student) }
  let(:section_to)   { create(:section_with_course) }
  let(:section_from) { build_stubbed(:section) }
  let(:valid_params) { [student.id, section_from.id, section_to.id] }
  let(:transfer)     { instance_double('StudentWorkTransfer', process: true, logger_data: {}) }
  let(:config) { instance_double('config') }
  let(:redis_cache) { instance_double('mock_redis') }

  before do
    allow(StudentWorkTransfer).to receive(:new).and_return(transfer)
    allow(M3::Application).to receive(:config).and_return(config)
    allow(config).to receive(:job_conflict_cache).and_return(redis_cache)
    allow(Sidekiq).to receive(:redis).and_return(redis_cache)
    ::GradebookEngine::Section.new(
      course_id: section_to.course_id,
      id: section_to.id,
      name: section_to.name
    ).save!
  end

  describe '#perform' do
    before do
      allow(redis_cache).to receive(:keys).with(GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY)
                                         .and_return([])
      allow(redis_cache).to receive(:set).with(StudentWorkTransferWorker::SWT_IN_PROGRESS_KEY,
                                               true)
                                         .and_return(true)
      allow(redis_cache).to receive(:del).and_return(true)
    end

    context 'with active section and gradebook section as destinations and no ' \
            'conflicting jobs' do
      it 'creates a StudentWorkTransfer object' do
        described_class.new.perform(*valid_params)
        expect(StudentWorkTransfer).to have_received(:new).with(*valid_params)
        expect(transfer).to have_received(:process)
      end

      it 'does not rerschedule a StudentWorkTransferWorker' do
        allow(described_class).to receive(:perform_in)
        described_class.new.perform(*valid_params)
        expect(described_class).not_to have_received(:perform_in)
      end
    end

    context 'with an archived section as destination' do
      before do
        section_to.archive
      end

      it 'does not create a StudentWorkTransfer object' do
        described_class.new.perform(*valid_params)
        expect(StudentWorkTransfer).not_to have_received(:new)
      end

      it 'does not reschedule a StudentWorkTransferWorker' do
        allow(described_class).to receive(:perform_in)
        described_class.new.perform(*valid_params)
        expect(described_class).not_to have_received(:perform_in)
      end
    end

    context 'without a GradebookEngine::Section for the destination' do
      before do
        ::GradebookEngine::Section.find(section_to.id).destroy!
      end

      it 'does not create a StudentWorkTransfer object' do
        described_class.new.perform(*valid_params)
        expect(StudentWorkTransfer).not_to have_received(:new)
      end

      it 'reschedules a StudentWorkTransferWorker to run in three minutes' do
        allow(described_class).to receive(:perform_in)
        described_class.new.perform(*valid_params)
        expect(described_class).to have_received(:perform_in).with(
          180,
          *valid_params
        )
      end
    end

    context 'with a conflicting GradebookSchoolMergeWorker worker' do
      before do
        allow(redis_cache).to receive(:keys).with(GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY)
                                           .and_return([GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY])
        allow(redis_cache).to receive(:del).and_return(true)
      end

      it 'does not create a StudentWorkTransfer object' do
        described_class.new.perform(*valid_params)
        expect(StudentWorkTransfer).not_to have_received(:new)
      end

      it 'reschedules a StudentWorkTransferWorker to run in three minutes' do
        allow(described_class).to receive(:perform_in)
        described_class.new.perform(*valid_params)
        expect(described_class).to have_received(:perform_in).with(180, *valid_params)
      end
    end
  end
end
