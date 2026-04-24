describe Cartridge::Converters::LessonConverter do
  let(:program) { create(:program) }
  let(:unit) { create(:unit_with_lessons_with_toc_entries, program: program) }
  let(:lesson) { unit.lessons.first }
  let(:toc_entries) { lesson.strands }
  let(:toc_entry_items) { toc_entries.map { MultiVersionCommonCartridge::Item.new } }
  let(:converter) { described_class.new(lesson) }

  before do
    toc_entries.each_with_index do |toc_entry, index|
      toc_entry_converter = instance_double(
        Cartridge::Converters::TocEntryConverter
      )
      allow(toc_entry_converter).to receive(:convert).and_return(toc_entry_items[index])
      allow(Cartridge::Converters::TocEntryConverter)
        .to receive(:new).with(toc_entry).and_return(toc_entry_converter)
    end
  end

  describe '#convert' do
    it 'returns an item' do
      expect(converter.convert).to be_a(MultiVersionCommonCartridge::Item)
    end

    describe 'the result item' do
      let(:item) { converter.convert }

      it 'sanitizes and sets the title' do
        sanitized_title = 'sanitized title'
        allow(converter).to receive(:sanitize_title)
          .with(lesson.name).and_return(sanitized_title)

        expect(item.title).to eq(sanitized_title)
      end

      it 'sets the identifier' do
        expect(item.identifier).to start_with('_')
      end

      it 'does not set the resource' do
        expect(item.resource).to be_nil
      end

      context 'when the program is a one-tier program,' do
        let(:unit) do
          create(:unit_with_lesson_with_toc_entries, program: program)
        end

        it 'converts all the toc_entries' do
          # Be sure the setup is correct and we have a one-tier program
          expect(program).not_to be_two_tier

          expect(item.children).to eq(toc_entry_items)
        end
      end
    end
  end
end
