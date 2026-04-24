describe ProgramToProgramMapping do
  let(:dest_program) { create(:program_with_toc_entries) }
  let(:src_program) { create(:program_with_toc_entries, language_code: dest_program.language_code) }
  let(:src_strand) { create(:concept, program: src_program, lesson: src_program.lessons.first) }
  let(:dest_strand) { create(:concept, program: dest_program, lesson: dest_program.lessons.first) }
  let(:program_to_program_mapping_1) do
    create(
      :program_to_program_mapping,
      dest_program: dest_program,
      dest_strand: dest_strand,
      src_strand: src_strand
    )
  end

  describe 'validations' do
    it 'requires a destination program' do
      program_to_program_mapping = described_class.new(dest_strand_id: dest_strand,
                                                       src_strand_id: src_strand)
      expect(program_to_program_mapping).not_to be_valid
    end

    it 'requires a source strand' do
      program_to_program_mapping = described_class.new(dest_program_id: dest_program,
                                                       dest_strand_id: dest_strand)
      expect(program_to_program_mapping).not_to be_valid
    end

    it 'requires a source strand to be unique' do
      program_to_program_mapping_2 = described_class.new(dest_program_id: dest_program,
                                                         dest_strand_id: dest_strand,
                                                         src_strand_id: src_strand)
      expect(program_to_program_mapping_2).not_to be_valid
    end
  end

  it 'returns the source program id' do
    expect(program_to_program_mapping_1.src_program_id).to eql src_program.id
  end

  describe '.source_program' do
    let(:source_program) { create(:program) }
    let(:destination_program) { create(:program) }
    let(:concept_for_source_program) do
      create(:concept, program: source_program)
    end

    it 'returns the source program if a program-to-program mapping ' \
       'exists for the given destination program' do
      create(:program_to_program_mapping,
             dest_program_id: destination_program.id,
             dest_strand: dest_strand,
             src_strand_id: concept_for_source_program.id)

      expect(described_class.source_program(destination_program)).to eq(source_program)
    end

    it 'returns nil if no program-to-program mapping exists for the given destination program' do
      expect(described_class.source_program(destination_program)).to be_nil
    end
  end
end
