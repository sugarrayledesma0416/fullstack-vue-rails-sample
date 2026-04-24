describe Cartridge::Converters::TitleSanitizer do
  class Sanitizer
    include Cartridge::Converters::TitleSanitizer
  end

  let(:sanitized_title) { Sanitizer.new.sanitize_title(title) }

  describe '#sanitize_title' do
    context 'when the title contains leading spaces,' do
      let(:title) { '   Olá, que tal?' }

      it 'deletes leading spaces' do
        expect(sanitized_title).to eq('Olá, que tal?')
      end
    end

    context 'when the title contains trailing spaces,' do
      let(:title) { 'Olá, que tal?  ' }

      it 'deletes leading spaces' do
        expect(sanitized_title).to eq('Olá, que tal?')
      end
    end

    context 'when the title contains duplicated spaces,' do
      let(:title) { 'Olá,  que  tal?' }

      it 'deletes duplicated spaces' do
        expect(sanitized_title).to eq('Olá, que tal?')
      end
    end

    context 'when the title contains html tags,' do
      let(:title) { '<b>Olá</b>, que tal?' }

      it 'strips all tags' do
        expect(sanitized_title).to eq('Olá, que tal?')
      end
    end

    context 'when the title contains html tags' do
      let(:title) { '  <b>Olá</b>, que tal? <b>Trailing spaces  </b>  ' }

      it 'strip all tags then delete leading, trailing and duplicated spaces' do
        expect(sanitized_title).to eq('Olá, que tal? Trailing spaces')
      end
    end

    context 'when the title contains html entities' do
      let(:title) { '&iexcl;Sue&ntilde;a' }

      it 'decodes the html entities' do
        expect(sanitized_title).to eq('¡Sueña')
      end
    end
  end
end
