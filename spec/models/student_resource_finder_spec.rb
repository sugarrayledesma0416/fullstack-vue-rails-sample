describe StudentResourceFinder do

  describe '#scope' do
    let!(:program)        { create(:program) }
    let(:instructor)      { create(:instructor) }
    let!(:section)        { create(:section, :instructor => instructor) }
    let!(:resource)       { create(:resource, :program => program, :vhl_student_resource => true) }
    let!(:other_resource) { create(:resource, :program => program, :vhl_student_resource => true) }

    context 'given a program' do
      it 'filters all resources by program' do
        other_resource.update!(:program => create(:program))
        finder = StudentResourceFinder.new(program, section)
        expect(finder.base_scope).to eq([resource])
      end
    end

    context 'given a protected resource' do
      it 'does not return the resource' do
        resource.update!(protected: true)
        other_resource.update!(protected: true)
        finder = StudentResourceFinder.new(program, section)
        expect(finder.base_scope).to be_empty
      end
    end

    context 'given a file type' do
      it 'only returns resources with that filetype' do
        resource.update!(file_type: 'foo')
        other_resource.update!(file_type: 'bar')
        finder = StudentResourceFinder.new(program, section, :resource_format => 'foo')
        expect(finder.base_scope).to eq([resource])
      end
    end

    context 'given a source' do
      it 'returns resources that match that source' do
        resource.update!(source: 'banana')
        other_resource.update!(source: 'apple')
        finder = StudentResourceFinder.new(program, section, :source => 'banana')
        expect(finder.base_scope).to eq([resource])
      end
    end

    context 'when a start_unit_id is provided' do
      context 'when the start_unit_id is actually a range of units' do
        it 'returns resources that have non-null start and end units' do
          resource.update! :start_unit_id => 1, :end_unit_id => 2
          other_resource.update!(:start_unit_id => 1, :end_unit_id => nil)
          finder = StudentResourceFinder.new(program, section, { :start_unit_id => ['1', '2'] })
          expect(finder.base_scope).to eq([resource])
        end
      end

      context 'when the start_unit_id is a single unit' do
        let(:start_unit) { create(:unit, program: program, rank: 1) }
        let(:middle_unit) { create(:unit, program: program, rank: 2) }
        let(:end_unit) { create(:unit, program: program, rank: 3) }
        let(:other_unit) { create(:unit, program: program, rank: 4) }

        before do
          resource.update! :start_unit_id => start_unit.id, :end_unit_id => end_unit.id
        end

        it 'returns any resources that match the unit' do
          other_resource.update!(start_unit_id: other_unit.id)
          finder = StudentResourceFinder.new(program, section, { :start_unit_id => start_unit.id })
          expect(finder.base_scope).to eq([resource])
        end

        it 'returns any resources that are in the unit range' do
          other_resource.update!(start_unit_id: other_unit.id)
          finder = StudentResourceFinder.new(program, section, { :start_unit_id => start_unit.id })
          expect(finder.base_scope).to eq([resource])
        end
      end
    end

    context 'when a component is provided' do
      it 'returns resources filtered by component' do
        resource_component_1 = create(:resource_component)
        resource.update!(resource_component_id: resource_component_1.id)
        resource_component_2 = create(:resource_component)
        other_resource.update!(resource_component_id: resource_component_2.id)

        finder = described_class.new(
          program,
          section,
          component_id: resource_component_1.id
        )
        expect(finder.base_scope).to eq([resource])
      end
    end

    context 'when no section is provided' do
      it 'returns any resources that are visible to students', test_debt: true do
        other_resource = create(:resource, :program => program)
        skip
      end
    end
  end
end
