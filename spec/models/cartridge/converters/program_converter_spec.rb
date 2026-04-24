describe Cartridge::Converters::ProgramConverter do
  let(:program_two_tier) { create(:two_tier_program_with_unit_in_lesson_names) }
  let(:program_one_tier) do
    create(:program).tap do |program|
      Array.new(3) do |index|
        create(:unit_with_lesson_with_toc_entries, program: program, name: "unit #{index + 1}")
      end
    end
  end
  let(:unit_items) { program.visible_units_and_resource_units.map { MultiVersionCommonCartridge::Item.new } }
  let(:resource_1) do
    create(:resource, program: program)
  end
  let(:resource_1_item) { MultiVersionCommonCartridge::Item.new }
  let(:resource_2) do
    create(:resource, program: program)
  end
  let(:resource_2_item) { MultiVersionCommonCartridge::Item.new }
  let(:resources) do
    [
      resource_1,
      resource_2
    ]
  end
  let(:resource_items) do
    [
      resource_1_item,
      resource_2_item
    ]
  end
  let(:base_resource_container_count) { 1 }
  let(:converter) { described_class.new(program) }

  before do
    program.units.each_with_index do |unit, index|
      unit_converter = instance_double(Cartridge::Converters::UnitConverter)
      allow(unit_converter).to receive(:convert).and_return(unit_items[index])
      allow(Cartridge::Converters::UnitConverter)
        .to receive(:new).with(unit).and_return(unit_converter)
    end

    resources.each_with_index do |resource, index|
      resource_converter = instance_double(
        Cartridge::Converters::ResourceConverter
      )
      allow(resource_converter).to receive(:convert).and_return(
        resource_items[index]
      )
      allow(Cartridge::Converters::ResourceConverter)
        .to receive(:new).with(resource).and_return(resource_converter)
    end
  end

  describe '#convert' do
    let(:cartridge) { converter.convert }
    let(:program) { program_one_tier }

    it 'returns a cartridge' do
      expect(converter.convert).to be_a(MultiVersionCommonCartridge::Cartridge)
    end

    it 'sanitizes and sets the cartridge manifest title' do
      sanitized_title = 'sanitized title'
      allow(converter).to receive(:sanitize_title)
        .with(program.title).and_return(sanitized_title)

      expect(cartridge.manifest.titles).to eq(
        'en-US' => sanitized_title
      )
    end

    it 'sets the cartridge manifest identifier' do
      expect(cartridge.manifest.identifier).to start_with('_')
    end

    context 'when the program is two tier,' do
      let(:program) { program_two_tier }

      it 'sets the cartridge items with the converted units and resources' do
        expect(program).to be_two_tier
        expect(cartridge.items).to include(*unit_items)
        expect(cartridge.items.last.children).to match_array resource_items
      end

      it 'excludes non released units' do
        program.units.last.update!(released: false)
        units_and_resources_items_count = program.units.count + base_resource_container_count
        expect(cartridge.items.count).to eq(units_and_resources_items_count - 1)
      end

      it 'excludes News and Cultura units' do
        program.units.last.update!(name: described_class::NEWS_AND_CULTURA_UNIT_NAME)
        units_and_resources_items_count = program.units.count + base_resource_container_count
        expect(cartridge.items.count).to eq(units_and_resources_items_count - 1)
      end
    end

    context 'when the program is not two tier,' do
      let(:program) { program_one_tier }
      let(:lesson_items) do
        program.lessons.map { MultiVersionCommonCartridge::Item.new }
      end

      before do
        program.lessons.each_with_index do |lesson, index|
          lesson_converter = instance_double(Cartridge::Converters::UnitConverter)
          allow(lesson_converter).to receive(:convert).and_return(lesson_items[index])
          allow(Cartridge::Converters::LessonConverter)
            .to receive(:new).with(lesson).and_return(lesson_converter)
         end
      end

      it 'sets the cartridge items with the converted lessons and resources' do
        expect(program).not_to be_two_tier
        expect(cartridge.items).to include(*lesson_items)
        expect(cartridge.items.last.children).to match_array resource_items
      end

      it 'excludes non released units' do
        program.units.last.update!(released: false)
        lessons_and_resources_items_count = program.lessons.count + base_resource_container_count
        expect(cartridge.items.count).to eq(lessons_and_resources_items_count - 1)
      end

      it 'excludes News and Cultura units' do
        program.units.last.update!(name: described_class::NEWS_AND_CULTURA_UNIT_NAME)
        lessons_and_resources_items_count = program.lessons.count + base_resource_container_count
        expect(cartridge.items.count).to eq(lessons_and_resources_items_count - 1)
      end
    end

    context 'when the program has vtext settings' do
      let(:program) { create(:program) }
      let(:vtext_item) do
        MultiVersionCommonCartridge::Item.new
      end

      before do
        vtext_converter = instance_double(Cartridge::Converters::VtextConverter)
        allow(vtext_converter).to receive(:convert).and_return(vtext_item)
        allow(Cartridge::Converters::VtextConverter)
          .to receive(:new).with(program).and_return(vtext_converter)
      end

      it 'sets the cartridge items with the vtext item and resources' do
        expect(cartridge.items).to include vtext_item
        expect(cartridge.items.last.children).to match_array resource_items
      end
    end
  end
end
