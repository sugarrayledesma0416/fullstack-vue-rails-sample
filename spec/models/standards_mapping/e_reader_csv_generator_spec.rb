module StandardsMapping
  describe EReaderCsvGenerator do
    describe '.generate_ereader_csv_string' do
      it 'writes a csv string' do
        expect(
          CSV.parse(described_class.generate_csv_string)
        ).to eq([StandardsMapping::EReaderCsvGenerator::EREADER_HEADERS])
      end
    end

    describe '.generate_toc_csv_for_ereader' do
      let(:program) { create(:program_with_lessons) }
      let(:expected) do
        [
          [program.title, program.id.to_s, '', '', '', ''],
          StandardsMapping::EReaderCsvGenerator::TOC_HEADERS
        ]
      end

      it 'writes a csv string' do
        program.units.each do |unit|
          expected << [unit.name, unit.id.to_s, '', '', '', '']
          unit.lessons.each do |lesson|
            expected << ['', '', lesson.name, lesson.id.to_s, '', '']
            # create 2 concepts for each lesson
            lesson.concepts = [create(:concept), create(:concept)]
            lesson.concepts.each do |concept|
              expected << ['', '', '', '', concept.name, concept.id.to_s]
            end
          end
        end
        expect(
          CSV.parse(described_class.generate_toc_csv(program.id))
        ).to eq(expected)
      end
    end
  end
end
