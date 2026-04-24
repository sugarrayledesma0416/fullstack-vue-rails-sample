describe DictionaryEntriesReportWorker do
  let(:program) { create(:program) }
  let(:program_id) { program.id }
  let(:cms_activity_ids) { [456, 789] }
  let(:file_path) { "tasks/dictionary_entries_reports/#{cms_activity_ids.join('-')}.csv" }
  let(:reporter) { DictionaryEntriesExport::DictionaryEntriesReport.new(program_id:, cms_activity_ids:) }

  before do
    allow(DictionaryEntriesExport::DictionaryEntriesReport).to receive(:new)
      .with(program_id:, cms_activity_ids:).and_return(reporter)
    allow(reporter).to receive(:generate_csv_file)
    allow(reporter).to receive(:delete_temp_csv_file)
    allow(reporter).to receive(:errors_export)
  end

  describe '#perform' do
    it 'does not execute the errors_export method there when there are not exceptions' do
      allow(reporter).to receive(:upload_csv_file)
      described_class.new.perform(program_id, cms_activity_ids)
      expect(reporter).not_to have_received(:errors_export)
    end

    it 'calls the DictionaryEntriesReport methods in the correct order' do
      allow(reporter).to receive(:upload_csv_file)
      described_class.new.perform(program_id, cms_activity_ids)
      expect(reporter).to have_received(:generate_csv_file).ordered
      expect(reporter).to have_received(:upload_csv_file).ordered
      expect(reporter).to have_received(:delete_temp_csv_file).ordered
    end

    it 'catches any execption during the report generation' do
      described_class.new.perform(program_id, cms_activity_ids)
      errors = reporter.instance_variable_get(:@errors)
      expect(errors.count).to eq(1)
    end

    it 'executes the errors_export method if there is an exception during the export' do
      described_class.new.perform(program_id, cms_activity_ids)
      expect(reporter).to have_received(:errors_export)
    end
  end
end
