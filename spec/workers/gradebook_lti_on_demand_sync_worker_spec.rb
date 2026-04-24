describe GradebookLtiOnDemandSyncWorker do
  let(:error_collector) do
    instance_double(
      GradebookEngine::Lti::ErrorCollector,
      has_errors?: false,
      has_warnings?: false
    )
  end
  let(:syncer) do
    instance_double(
      GradebookEngine::Lti::ContextLinkSyncer,
      context_link:,
      disabled_on_lms?: false,
      error_collector:,
      sync: true
    )
  end
  let(:worker) { described_class.new }
  let(:course) { create(:gb_course) }
  let(:section) { create(:gb_section, course:) }
  let(:context_link) do
    create(
      :gb_lti_context_link,
      context_id: SecureRandom.hex(10),
      id: 16,
      section_id: section.id,
      sync_level: 'cumulative'
    )
  end
  let(:logger_data) do
    {
      course_id: section.course_id,
      lms_context_id: context_link.context_id,
      params: { context_link_id: context_link.id },
      school_id: section.school_id,
      section_id: section.id,
      section_name: section.name,
      sync_level: context_link.sync_level
    }
  end

  before do
    allow(GradebookEngine::Lti::ContextLinkSyncer).to receive(:new)
      .and_return(syncer)
    allow(worker).to receive(:logger_data_merge).with(logger_data)
  end

  it 'creates a syncer class and initiates a syncing process' do
    worker.perform(context_link.id)
    expect(syncer).to have_received(:sync)
  end

  it 'aborts if another job with the same name and args is running' do
    allow(GradebookEngine::Lti::MultiContextLinkSyncer).to receive(:new)
    allow(worker).to receive(:identical_process_running?)
      .with(context_link.id)
      .and_return(true)
    allow(worker).to receive(:logger_data_merge)

    worker.perform(context_link.id)

    expect(GradebookEngine::Lti::MultiContextLinkSyncer).not_to have_received(:new)
    expect(worker).to have_received(:logger_data_merge).with(
      errors: ['Conflict with identical sync job']
    )
  end

  it 'logs params data' do
    worker.perform(context_link.id)
    expect(worker).to have_received(:logger_data_merge).with(logger_data)
  end

  it 'logs errors' do
    errors = [
      {
        category: :some_category,
        context: 'Action 1',
        message: 'error message 1'
      } => 1,
      {
        category: :some_category,
        context: 'Action 2',
        message: 'error message 2'
      } => 2
    ]
    allow(worker).to receive(:logger_data_merge)
    allow(error_collector).to receive(:has_errors?).and_return(true)
    allow(error_collector).to receive(:errors).and_return(errors)

    worker.perform(context_link.id)

    expect(worker).to have_received(:logger_data_merge).with(
      hash_including(errors:)
    )
  end

  it 'logs warnings' do
    warnings = [
      {
        category: :some_category,
        context: 'Action 1',
        message: 'warning message 1'
      } => 1,
      {
        category: :some_category,
        context: 'Action 2',
        message: 'warning message 2'
      } => 2
    ]
    allow(worker).to receive(:logger_data_merge)
    allow(error_collector).to receive(:has_warnings?).and_return(true)
    allow(error_collector).to receive(:warnings).and_return(warnings)

    worker.perform(context_link.id)

    expect(worker).to have_received(:logger_data_merge).with(
      hash_including(warnings:)
    )
  end
end
