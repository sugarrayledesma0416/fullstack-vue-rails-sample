describe SubmissionMigrator, core: true do
  describe '#sync_api' do
    let(:attempt) { create(:attempt) }
    let(:xml_store)  { double('ResultsXmlDatastore') }
    let(:api_store)  { double('ResultsApiDatastore') }
    let(:submission_migrator) { described_class }
    let(:fixture_file) { File.join('spec', 'fixtures', 'xml', 'ruby187_responses_with_accents.xml') }
    let(:filepath) { 'datafiles/test/responses/2/3.xml' }

    before(:each) do
      allow(xml_store).to receive(:stored_responses).and_return('results')
      allow(xml_store).to receive(:saved_responses).and_return('results')

      allow(submission_migrator).to receive(:results_api_datastore).and_return(api_store)
      allow(submission_migrator).to receive(:results_xml_datastore).and_return(xml_store)
    end

    it 'syncs the submitted values when one exists and updates submission_id' do
      allow(attempt).to receive(:submitted_values?).and_return(true)
      allow(attempt).to receive(:saved_values?).and_return(false)

      expect(api_store).to receive(:write).with('results').and_return(101)
      expect(xml_store).to receive(:stored_responses).and_return('results')

      submission_migrator.sync_api(attempt)
      expect(attempt.submission_id).to eql(101)
    end

    it 'syncs the saved values when one exists and updates saved_submission_id' do
      allow(attempt).to receive(:submitted_values?).and_return(false)
      allow(attempt).to receive(:saved_values?).and_return(true)

      expect(xml_store).to receive(:saved_responses).and_return('results')
      expect(api_store).to receive(:write).with('results').and_return(101)

      submission_migrator.sync_api(attempt)
      expect(attempt.saved_submission_id).to eql(101)
    end
  end
end
