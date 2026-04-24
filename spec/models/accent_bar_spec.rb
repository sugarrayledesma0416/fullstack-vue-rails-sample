describe AccentBar do
  describe '#characters' do
    it 'returns the special characters for Spanish' do
      characters = %w[
        á Á
        é É
        í Í
        ñ Ñ
        ó Ó
        ú Ú
        ü Ü
        ¿ ¿
        ¡ ¡
      ].each_slice(2).to_a
      expect(described_class.characters('es')).to eq(characters)
    end

    it 'returns the special characters for French' do
      characters = %w[
        à À
        â Â
        ç Ç
        è È
        é É
        ê Ê
        ë Ë
        î Î
        ï Ï
        ô Ô
        œ Œ
        ù Ù
        û Û
        ü Ü
      ].each_slice(2).to_a
      expect(described_class.characters('fr')).to eq(characters)
    end

    it 'returns the special characters for Italian' do
      characters = %w[
        à À
        è È
        é É
        ì Ì
        ò Ò
        ó Ó
        ù Ù
      ].each_slice(2).to_a
      expect(described_class.characters('it')).to eq(characters)
    end

    it 'returns the special characters for German' do
      characters = %w[
        ä Ä
        ö Ö
        ü Ü
        ß
      ].each_slice(2).to_a
      expect(described_class.characters('de')).to eq(characters)
    end

    it 'returns a empty collection of characters for English' do
      expect(described_class.characters('en')).to eq([])
    end

    it 'returns a empty collection of characters for Chinese' do
      expect(described_class.characters('zh')).to eq([])
    end

    it 'returns a empty collection of characters for Russian' do
      expect(described_class.characters('ru')).to eq([])
    end

    it 'raises an error for any other language' do
      expect do
        described_class.characters('yn')
      end.to raise_error(NoMethodError, /undefined method `yn'/)
    end

    it 'raises an error when no language is specified' do
      expect do
        described_class.characters('')
      end .to raise_error(NoMethodError, /undefined method `'/)
    end
  end
end
