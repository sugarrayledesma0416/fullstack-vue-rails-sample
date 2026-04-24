describe Language do
  describe '.all' do
    it 'returns all languages, sorted by language name' do
      expect(described_class.all).to contain_exactly(
        %w[fr French],
        %w[de German],
        %w[it Italian],
        %w[es Spanish],
        %w[en English],
        %w[zh Chinese],
        %w[ru Russian]
      )
    end
  end

  describe '.names_from_codes' do
    it 'returns a single language name when given one code' do
      expect(described_class.names_from_codes('es')).to eq('Spanish')
    end

    it 'returns a list of language names when given a list of codes' do
      expect(described_class.names_from_codes('es,fr')).to eq('French, Spanish')
    end

    it 'returns empty string if no codes are passed' do
      expect(described_class.names_from_codes(nil)).to eq('')
    end
  end
end
