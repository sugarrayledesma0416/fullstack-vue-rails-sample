describe Concept do
  let(:unit) { build_stubbed(:unit, program: build_stubbed(:program, maestro_version: 3)) }
  let(:lesson) { build_stubbed(:lesson, label: 'Lesson 1', unit: unit) }
  let(:concept) { build_stubbed(:concept, lesson: lesson, name: 'contextos') }

  describe '#label' do
    it 'returns the lesson short name concatenated with the concept name' do
      expect(concept.label).to eql 'Lesson 1: contextos'
    end
  end

  describe '#base_name' do
    let(:concept) do
      build_stubbed(
        :concept,
        lesson: lesson,
        name: 'Estructura 1.1',
        base_name: 'Estructura'
      )
    end

    it 'returns the base_name when present' do
      expect(concept.base_name).to eq('Estructura')
    end

    it 'returns the name value when base_name is empty' do
      concept.base_name = ''
      expect(concept.base_name).to eq('Estructura 1.1')
    end

    it 'strips out white spaces' do
      concept.base_name = '     something    '
      expect(concept.base_name).to eql('something')

      concept.base_name = '   '
      concept.name = ' another name    '
      expect(concept.base_name).to eql('another name')
    end
  end

  describe '#concept_combined_rank' do
    concept = described_class.new
    concept.rank = 1
    concept.lesson_combined_rank = 102

    it 'return rank when combined_rank is called' do
      expect(concept.concept_combined_rank).to eq(10_201)
    end
  end

  context 'update_gradebook' do
    context 'after commit' do
      let(:strand) { create(:toc_entry) }
      let(:concept) { create(:concept, id: strand.location) }

      it 'triggers update_gradebook in after_commit' do
        concept.name = 'Pronuncuacion'
        expect(concept).to receive(:update_gradebook)
        concept.save
      end

      it 'triggers notify_update when concept is created' do
        aconcept = build(:concept)
        aconcept.name = 'Pronuncuacion'
        expect(aconcept).to receive(:notify_update)
        aconcept.save!
      end

      it 'triggers notify_deletion for a destroyed concept' do
        expect(concept).to receive(:notify_deletion)
        concept.destroy
      end
    end
  end
end
