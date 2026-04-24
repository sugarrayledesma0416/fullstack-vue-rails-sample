describe Instructor::DashboardHelper do
  include described_class

  describe '#show_section_average?' do
    context 'when student count is within threshold' do
      it 'returns true for exactly 50 students' do
        expect(show_section_average?(50)).to be true
      end

      it 'returns true for 25 students' do
        expect(show_section_average?(25)).to be true
      end
    end

    context 'when student count exceeds threshold' do
      it 'returns false for 51 students' do
        expect(show_section_average?(51)).to be false
      end
    end
  end
end
