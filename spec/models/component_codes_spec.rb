describe ComponentCodes do
  let(:program_1) { create(:program) }
  let(:program_2) { create(:program) }
  let(:program_1_unit) { create(:unit, program: program_1) }
  let(:program_2_unit) { create(:unit, program: program_2) }
  let(:program_1_strand) { create(:toc_entry) }
  let(:program_2_strand) { create(:toc_entry) }
  let(:program_1_lesson) do
    create(:lesson, toc_entries: [program_1_strand], unit: program_1_unit)
  end
  let(:program_2_lesson) do
    create(:lesson, toc_entries: [program_2_strand], unit: program_2_unit)
  end
  let(:component_1_name) { 'lab manual' }
  let(:component_2_name) { 'practice activities' }
  let(:unwanted_component) { 'nickelback' }

  before do
    create(
      :concept,
      id: program_1_strand.location,
      lesson: program_1_lesson,
      program: program_1
    )
    create(
      :concept,
      id: program_2_strand.location,
      lesson: program_2_lesson,
      program: program_2
    )

    allow(Maestro::LicenseGroup).to receive(:all).and_return(
      [instance_double(Maestro::LicenseGroup, name: '01-Supersite', id: 1)]
    )
    create(
      :activity,
      component_name: component_1_name,
      lesson: program_1_lesson
    )
    create(
      :activity,
      component_name: component_2_name,
      lesson: program_2_lesson
    )
  end

  describe '#components' do
    it 'returns an hash of components for the program' do
      expect(described_class.new(program_1.id).components).to eq([component_1_name])
    end

    it 'returns unique components for the program' do
      create(:activity, lesson: program_2_lesson, component_name: component_2_name)
      expect(described_class.new(program_2.id).components).to eq([component_2_name])
    end

    it 'filters out components from IGC activities' do
      stub_request(
        :any,
        %r{https\:\/\/s3\.amazonaws\.com\/vhlcentral\.activities/.*\.xml}
      ).to_return(status: 200, body: '', headers: {})

      create(
        :instructor_created_activity_with_non_db_attrs,
        component_name: unwanted_component,
        lesson: program_2_lesson,
        toc_entry_id: program_2_strand.location
      )
      expect(described_class.new(program_2.id).components).to eq([component_2_name])
    end

    it 'filters out components from unlinked activities' do
      create(
        :activity,
        component_name: unwanted_component,
        lesson: program_1_lesson,
        toc_location: nil
      )
      expect(described_class.new(program_1.id).components).to eq([component_1_name])
    end

    context 'when there are no components for the program' do
      it 'returns an empty array' do
        another_program = create(:program)
        expect(described_class.new(another_program).components).to eq([])
      end
    end
  end
end
