require 'activity_time_spent_average'

describe ActivityTimeSpentAverage do
  describe '#percentile' do
    it 'returns the desired percentile' do
      values = [2,6,9,3,5,1,8,3,6,9,2]
      tsa = described_class.new(activity_type: 'blank')
      expect(tsa.percentile(values, 0.30)).to eq 3.0
      expect(tsa.percentile(values, 0.70)).to eq 6.0
      expect(tsa.percentile(values, 0.90)).to eq 9.0
      expect(tsa.percentile(values, 0.95)).to eq 9.0
    end
  end
end
