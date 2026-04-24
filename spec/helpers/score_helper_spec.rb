describe ScoreHelper do
  include ScoreHelper
  include GradebookHelper
  describe '#format_time_spent,' do
    it 'returns an empty string when time_spent is nil' do
      expect(format_time_spent(nil)).to eql ''
    end

    it 'returns an empty string when time_spent is empty string' do
      expect(format_time_spent('')).to eql ''
    end

    it 'returns an empty string when time_spent is zero' do
      expect(format_time_spent(0)).to eql ''
    end

    it 'returns a string formatted in MM:SEC when time_spent is less than an hour' do
      expect(format_time_spent(90)).to eql '1:30'
    end

    it 'returns a string formatted in HR:MM:SEC when time_spent is more than or equal to an hour' do
      expect(format_time_spent(3600)).to eql '1:00:00'
    end

    it 'returns a properly formatted string when time exceeds 2 hours' do
      expect(format_time_spent(7510)).to eql '2:05:10'
    end
  end

  describe '#format_current_score' do
    let(:score) do
      instance_double(::GradebookEngine::AssignmentGrade,
                      net_ratio: 0.0, pending?: false, partial_pending?: false)
    end

    it 'returns a valid percent string ' do
      expect(format_current_score(score)).to eql '0.0%'
    end

    it 'returns pending if score is pending' do
      allow(score).to receive(:pending?).and_return(true)
      expect(format_current_score(score)).to eql 'Pending'
    end

    it 'returns blank if score is nil' do
      expect(format_current_score(nil)).to eql ''
    end

    it 'returns pending when the score is partially pending' do
      allow(score).to receive(:partial_pending?).and_return(true)
      expect(format_current_score(score)).to eql 'Pending'
    end
  end
end
