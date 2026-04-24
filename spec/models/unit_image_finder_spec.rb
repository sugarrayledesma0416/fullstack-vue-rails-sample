describe UnitImageFinder do
  describe '.unit_image' do
    it 'returns nil if no unit with the specified id exists' do
      expect(described_class.unit_image(0)).to be_nil
    end

    context 'when a unit with the specified id exists' do
      it 'returns nil if the unit has no media item' do
        unit = create(:unit)

        expect(described_class.unit_image(unit.id)).to be_nil
      end

      it 'returns the media item of the unit when one exists' do
        media_item = create(:media_item)
        unit = create(:unit, media_item: media_item)

        expect(described_class.unit_image(unit.id)).to eq(media_item)
      end
    end
  end
end
