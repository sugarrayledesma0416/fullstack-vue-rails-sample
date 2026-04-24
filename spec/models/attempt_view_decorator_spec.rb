describe AttemptViewDecorator, core: true do
  let(:instructor) { build(:instructor) }
  let(:attempt) { build(:attempt).extend(described_class) }

  describe '#in_completed_view_without_results?' do
    it 'returns true if results do not exist and current_view is completed' do
      allow(attempt).to receive(:current_view).and_return(:complete)
      allow(attempt).to receive(:results).and_return(nil)
      expect(attempt.in_completed_view_without_results?).to eq true
    end

    it 'returns false if results exist and current_view is not completed' do
      allow(attempt).to receive(:current_view).and_return(:show)
      allow(attempt).to receive(:results).and_return(true)
      expect(attempt.in_completed_view_without_results?).to eq false
    end
  end

  describe '#assign_practice_complete' do
    it 'assigns practice_complete to true if commit is answers or results are complete' do
      commit = 'Answers'
      attempt.assign_practice_complete(commit, true)
      expect(attempt.practice_complete?).to eq true
      expect(attempt.status_code).to eq AttemptStatus::CODE_COMPLETED
    end
  end

  describe '#assign_view_and_notice' do
    let(:commit) { 'Check' }

    it 'returns show view if user is instructor' do
      attempt.update(user: instructor)
      expect(attempt.assign_view_and_notice(commit)).to eq [:show]
    end

    it 'returns complete view and a notice if practice_complete' do
      allow(attempt).to receive(:practice_complete?).and_return(true)
      expected = [:complete, 'Viewing answers.']
      expect(attempt.assign_view_and_notice(commit)).to eq expected
    end

    it 'returns submit view and a notice if commit is "Check"' do
      expected = [:submit, 'Practice mode. Answers will not be saved!']
      expect(attempt.assign_view_and_notice(commit)).to eq expected
    end

    it 'returns show view if any condition is not met' do
      expected = [:show, 'Practice mode. Answers will not be saved!']
      expect(attempt.assign_view_and_notice('wront_commit')).to eq expected
    end
  end
end
