describe Cartridge::Converters::UnitConverter do
  let(:program) { create(:program) }
  let(:units) do
    Array.new(3) do |index|
      create(
        :unit_with_lessons,
        rank: index + 1,
        use_type: 'Unit',
        program: program
      )
    end
  end
  let(:unit) { units.second }
  let(:lesson_items) do
    unit.lessons.map { MultiVersionCommonCartridge::Item.new }
  end
  let(:converter) { described_class.new(unit) }

  before do
    unit.lessons.each_with_index do |lesson, index|
      lesson_converter = instance_double(
        Cartridge::Converters::LessonConverter
      )
      allow(lesson_converter).to receive(:convert).and_return(
        lesson_items[index]
      )
      allow(Cartridge::Converters::LessonConverter)
        .to receive(:new).with(lesson).and_return(lesson_converter)
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
          .with(unit.name).and_return(sanitized_title)

        expect(item.title).to eq(sanitized_title)
      end

      it 'sets the identifier' do
        expect(item.identifier).to start_with('_')
      end

      it 'does not set the resource' do
        expect(item.resource).to be_nil
      end

      context 'when the program is a one-tier program,' do
        let(:units) do
          Array.new(3) do |index|
            create(
              :unit_with_lesson,
              rank: index + 1,
              use_type: 'Unit',
              program: program
            )
          end
        end

        before do
          # Be sure the setup is correct and we have a one-tier program
          expect(program).not_to be_two_tier
        end

        it 'converts all the lessons that are for this unit' do
          expect(item.children).to eq lesson_items
        end
      end
    end
  end
end
