describe Cartridge::Converters::TocEntryConverter do
  let(:unit) { create(:unit_with_lessons_with_toc_entries) }
  let(:lesson) { unit.lessons.first }
  let(:toc_entry) { lesson.toc_entries.first }
  let(:activity_1) do
    create(:activity, lesson: lesson, toc_location: toc_entry.location)
  end
  let(:activity_2) do
    create(:activity, lesson: lesson, toc_location: toc_entry.location)
  end
  let(:activity_1_item) { MultiVersionCommonCartridge::Item.new }
  let(:activity_2_item) { MultiVersionCommonCartridge::Item.new }
  let(:sub_strand_items) do
    toc_entry.children.map { MultiVersionCommonCartridge::Item.new }
  end
  let(:converter) { described_class.new(toc_entry) }

  before do
    # Mock the converter for each activity
    {
      activity_1 => activity_1_item,
      activity_2 => activity_2_item
    }.each do |activity, item|
      activity_converter = instance_double(Cartridge::Converters::ActivityConverter)
      allow(activity_converter).to receive(:convert).and_return(item)
      allow(Cartridge::Converters::ActivityConverter)
        .to receive(:new).with(activity).and_return(activity_converter)
    end

    # mock the converter for each sub strand
    toc_entry.children.each_with_index do |sub_strand, index|
      sub_strand_converter = instance_double(described_class)
      allow(sub_strand_converter).to receive(:convert).and_return(sub_strand_items[index])
      allow(described_class).to receive(:new).with(sub_strand).and_return(sub_strand_converter)
    end

    allow(described_class).to receive(:new).with(toc_entry).and_call_original
  end

  describe '#convert' do
    shared_examples 'it does not export the activity' do
      let(:activity_2) do
        create(
          :activity,
          activity_type: excluded_activity_type,
          lesson:,
          toc_location: toc_entry.location
        )
      end

      it 'does not export this activity' do
        expect(item.children).to match_array(
          [activity_1_item] + sub_strand_items
        )
      end
    end

    it 'returns an item' do
      expect(converter.convert).to be_a(MultiVersionCommonCartridge::Item)
    end

    describe 'the result item' do
      let(:item) { converter.convert }

      it 'sanitizes and sets the title' do
        sanitized_title = 'sanitized title'
        allow(converter).to receive(:sanitize_title)
          .with(toc_entry.name).and_return(sanitized_title)

        expect(item.title).to eq(sanitized_title)
      end

      it 'sets the identifier' do
        expect(item.identifier).to start_with('_')
      end

      it 'does not set the resource' do
        expect(item.resource).to be_nil
      end

      describe 'item.children' do
        it 'converts all the activities and set the result items as children' do
          expect(item.children).to match_array(
            [activity_1_item, activity_2_item] + sub_strand_items
          )
        end
      end

      context 'when then toc entry contains a smart book activity,' do
        let(:excluded_activity_type) { 'smart_book' }

        include_examples 'it does not export the activity'
      end

      context 'when then toc entry contains a partner chat activity,' do
        let(:excluded_activity_type) { 'partner_chat' }

        include_examples 'it does not export the activity'
      end

      context 'when then toc entry contains a group chat activity,' do
        let(:excluded_activity_type) { 'group_chat' }

        include_examples 'it does not export the activity'
      end
    end
  end
end
