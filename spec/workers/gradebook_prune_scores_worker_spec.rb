describe GradebookPruneScoresWorker do
  describe '#perform' do
    it 'tells the gradebook engine to prune scores for the given course' do
      expect(GradebookEngine::GradebookAPI).to receive(:prune_scores)
      described_class.new.perform(123)
    end
  end
end
