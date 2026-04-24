module StandardsMapping
  describe IngestedTeItemGenerator do
    let(:not_te_program) { create(:program) }
    let(:concept) { create(:concept_for_test) }
    let(:ereader_item) { create(:e_reader_item, concept:) }
    let(:expected_headers) do
      StandardsMapping::IngestedTeItemGenerator::EREADER_ITEMS_HEADERS
    end

    let(:expected_data) do
      CSV.parse(described_class.generate_csv(concept.program_id)).last
    end

    before do
      allow(EReaderItem)
        .to receive(:ereader_items_by_program).with(concept.program_id).and_return(ereader_item)
    end

    describe '.extracted_data_ereader_items' do
      it 'writes a csv with the correct headers' do
        expect(
          described_class.extracted_data_ereader_items(concept.program_id).first.keys
        )
          .to eq(expected_headers)
      end
    end

    describe '.generate_csv' do
      # uFEFF  adds the Byte Order Mark (BOM) and it also adds a leading white space.
      let(:headers_with_ufeff_format) do
        ['guid'.prepend("\uFEFF"), 'title', 'page_section', 'descriptor', 'page_number', 'concept_id']
      end
      let(:expected) do
        [headers_with_ufeff_format, expected_data]
      end

      it 'writes a csv with the expected data' do
        expect(
          CSV.parse(described_class.generate_csv(concept.program_id))
        ).to eq(expected)
      end
    end

    describe '.ereader_items_by_program' do
      context 'when there are TE items for the program' do
        it 'returns the ereader items' do
          expect(
            described_class.ereader_items_by_program(concept.program_id).count
          ).to eq(1)
        end
      end

      context 'when there are no TE items for the program' do
        it 'does not return the ereader items' do
          expect(
            described_class.ereader_items_by_program(not_te_program.id)
          ).to be_empty
        end
      end
    end
  end
end
