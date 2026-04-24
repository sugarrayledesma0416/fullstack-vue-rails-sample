describe A11yReportGeneratorWorker do
  let(:program) { create(:program) }
  let(:include_details) { false }
  let(:report_tool) { A11yReportGenerator.new(program.id, include_details) }

  describe '#perform' do
    it 'Calls the A11yReportGenerator which returns true' do
      allow(A11yReportGenerator).to receive(:new).and_return(report_tool)
      allow(report_tool).to receive(:delete_file).and_return(true)
      response = described_class.new.perform(program.id, include_details)
      expect(response).to be(true)
    end
  end
end
