describe Standard do
  describe '#match_grade_levels?' do
    let(:standard) { create(:standard, additional_info: { additional_info: { grade_levels: '1,2,3' } }.to_json) }
    let(:program) { create(:program) }
    let(:standard_set) { create(:standard_set) }
    let(:program_settings) { instance_double(ProgramSettings, standard_grade_levels: %w[K 1 2 3 4])  }

    before do
      allow(ProgramSettings).to receive(:new).with(program).and_return(program_settings)
      allow(program_settings).to receive(:supported_standard_sets).and_return([standard_set])
    end

    it 'returns true if any program grade levels match the standard grade levels' do
      expect(standard.match_grade_levels?(program)).to be true
    end

    it 'returns false if no program grade levels match the standard grade levels' do
      allow(program_settings).to receive(:standard_grade_levels).and_return(%w[4 5 6])
      expect(standard.match_grade_levels?(program)).to be false
    end
  end
end
