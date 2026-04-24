describe InstructorResourcesExportWorker do
  let(:program) { create(:program) }

  describe '#perform' do
    it 'Calls the InstructorResourcesExport class and returns true' do
      response = described_class.new.perform(program.id)
      expect(response).to eq(true)
    end
  end
end
