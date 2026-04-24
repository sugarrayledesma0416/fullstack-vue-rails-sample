describe EbooksPresenter do
  let(:program_id) { build_stubbed(:program).id }
  let(:book_const) { "#{described_class}::BOOKS" }
  let(:ios_ebook) { double(described_class::IosEbook) }

  describe '#ios_ebook' do
    context 'when specified program has book data with an ios id' do
      it 'instantiates and returns an instance of IosEbook' do
        stub_const(book_const, program_id => { ios_id: 1 })
        expect(described_class::IosEbook).to receive(:new) { ios_ebook }
        expect(described_class.new(program_id).ios_ebook).to eq(ios_ebook)
      end
    end

    context 'when specified program has empty book data' do
      it 'does not instantiate and return an instance of IosEbook' do
        stub_const(book_const, program_id => {})
        expect(described_class::IosEbook).not_to receive(:new)
        expect(described_class.new(program_id).ios_ebook).to be_falsey
      end
    end

    context 'when specified program has book data with a bookshelf id' do
      it 'does not instantiate and return an instance of IosEbook' do
        stub_const(book_const, program_id => { bookshelf_id: 1 })
        expect(described_class::IosEbook).not_to receive(:new)
        expect(described_class.new(program_id).ios_ebook).to be_falsey
      end
    end
  end

  describe '#vitalsource_ebook?' do
    it 'is false when specified program has empty book data' do
      stub_const(book_const, program_id => {})
      expect(described_class.new(program_id).vitalsource_ebook?).to be_falsey
    end

    it 'is false when specified program has book data with an ios id' do
      stub_const(book_const, program_id => { ios_id: 1 })
      expect(described_class.new(program_id).vitalsource_ebook?).to be_falsey
    end

    it 'is true when specified program has book data with a bookshelf id' do
      stub_const(book_const, program_id => { bookshelf_id: 1 })
      expect(described_class.new(program_id).vitalsource_ebook?).to be_truthy
    end
  end

  describe '#vitalsource_book_id' do
    it 'returns the bookshelf id from the book data' do
      book_id = 1234
      stub_const(book_const, program_id => { bookshelf_id: book_id })
      expect(described_class.new(program_id).vitalsource_book_id).to eq(book_id)
    end
  end

  describe '#use_smartbanner?' do
    it 'is false when specified program has no book data' do
      stub_const(book_const, {})
      expect(described_class.new(program_id).use_smartbanner?).to be_falsey
    end

    it 'is false when specified program has empty book data' do
      stub_const(book_const, program_id => {})
      expect(described_class.new(program_id).use_smartbanner?).to be_falsey
    end

    it 'is false when specified program has book data with a bookshelf id' do
      stub_const(book_const, program_id => { bookshelf_id: 1 })
      expect(described_class.new(program_id).use_smartbanner?).to be_falsey
    end

    it 'is true when specified program has book data with an ios id' do
      stub_const(book_const, program_id => { ios_id: 1 })
      expect(described_class.new(program_id).use_smartbanner?).to be_truthy
    end
  end

  describe '#ebook_released?' do
    it 'is false when specified program has no book data' do
      stub_const(book_const, {})
      expect(described_class.new(program_id).ebook_released?).to be_falsey
    end

    it 'is false when specified program has empty book data' do
      stub_const(book_const, program_id => {})
      expect(described_class.new(program_id).ebook_released?).to be_falsey
    end

    it 'is true when specified program has book data with an ios id' do
      stub_const(book_const, program_id => { ios_id: 1 })
      expect(described_class.new(program_id).ebook_released?).to be_truthy
    end

    it 'is true when specified program has book data with a bookshelf id' do
      stub_const(book_const, program_id => { bookshelf_id: 1 })
      expect(described_class.new(program_id).ebook_released?).to be_truthy
    end
  end
end

describe EbooksPresenter::IosEbook do
  let(:ios_id) { '1234' }
  let(:ios_path) { 'vhl-app' }

  describe '#display_url' do
    context 'when vanity argument is true' do
      it 'returns a url based on the vanity base url' do
        ebook = described_class.new(ios_id: ios_id, ios_path: ios_path,
                                    vanity: true)
        expect(ebook.display_url).to eq("#{described_class::VANITY_URL}vhlapp")
      end
    end

    context 'when vanity argument is false' do
      it 'returns a url based on the itunes base url' do
        ebook = described_class.new(ios_id: ios_id, ios_path: ios_path,
                                    vanity: false)
        expected_url = "#{described_class::ITUNES_URL}vhl-app/id1234"
        expect(ebook.display_url).to eq(expected_url)
      end
    end
  end
end
