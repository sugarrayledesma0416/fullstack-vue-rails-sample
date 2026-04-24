describe BaseVideoSubmission, core: true do
  let(:activity) { build_stubbed(:activity) }
  let(:results) do
    instance_double(
      MaestroActivityEngine::ActivityContent::Results,
      first: { label: 'label' }
    )
  end
  let(:recording_path) { 'fake/base_video/recording/path' }

  describe '#response' do
    it 'looks up response from result based on the label' do
      allow(results).to receive(:response).with('label').and_return('response')
      submission = described_class.new(results, activity, {})
      allow(submission).to receive(:results).and_return(results)
      expect(submission.response).to eq('response')
    end
  end

  describe '#label' do
    it 'returns the label used to lookup the response' do
      submission = described_class.new(results, activity, {})
      expect(submission.label).to eq 'label'
    end
  end

  describe '#recording' do
    it 'returns raise NotImplementedError' do
      submission = described_class.new(results, activity, {})
      expect { submission.recording }.to raise_error(NotImplementedError)
    end
  end

  describe '#prepare_for_submission' do
    it 'returns raise NotImplementedError' do
      submission = described_class.new(results, activity, {})
      expect { submission.prepare_for_submission('activity_complete', 'time_now') }.to raise_error(NotImplementedError)
    end
  end
end