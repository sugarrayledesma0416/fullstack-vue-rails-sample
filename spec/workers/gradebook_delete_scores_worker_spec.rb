describe GradebookDeleteScoresWorker do
  describe '#perform' do
    it 'tells the gradebook engine to delete scores for the given course' do
      expect(GradebookEngine::GradebookAPI).to receive(:delete_scores)
      described_class.new.perform(123)
    end
  end
end
