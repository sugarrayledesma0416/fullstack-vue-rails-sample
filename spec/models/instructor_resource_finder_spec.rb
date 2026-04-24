describe InstructorResourceFinder do

  describe '#scope' do
    let!(:program) { create(:program) }
    let!(:instructor) { create(:instructor) }
    let!(:resource) { create(:resource, program: program, file_type: 'foo', source: 'banana') }

    context 'given a program' do
      it 'filters all resources by program' do
        other_resource = create(:resource)
        finder = InstructorResourceFinder.new(instructor, program)
        expect(finder.base_scope).to eq([resource])
      end
    end

    context 'when a file type is provided' do
      it 'only returns resources with that filetype' do
        other_resource = create(:resource, :program => program, :file_type => 'bar')
        finder = InstructorResourceFinder.new(instructor, program, { :resource_format => 'foo' })
        expect(finder.base_scope).to eq([resource])
      end
    end

    context 'when a source is provided' do
      it 'only returns resources with that source' do
        other_resource = create(:resource, :program => program, :source => 'apple')
        finder = InstructorResourceFinder.new(instructor, program, { :source => 'banana' })
        expect(finder.base_scope).to eq([resource])
      end
    end

    context 'when a start_unit_id is provided' do
      context 'when the start_unit_id is actually a range of units' do
        it 'returns resources that have non-null start and end units' do
          resource.start_unit_id, resource.end_unit_id = 1, 2
          resource.save!
          other_resource = create(:resource, :program => program, :source => 'apple', :start_unit_id => 1, :end_unit_id => nil)
          finder = InstructorResourceFinder.new(instructor, program, { :start_unit_id => ['1', '2'] })
          expect(finder.base_scope).to eq([resource])
        end
      end

      context 'when the start_unit_id is a single unit' do
        let(:start_unit) { create(:unit, program: program, rank: 1) }
        let(:middle_unit) { create(:unit, program: program, rank: 2) }
        let(:end_unit) { create(:unit, program: program, rank: 3) }
        let(:other_unit) { create(:unit, program: program, rank: 4) }

        before do
          resource.start_unit_id, resource.end_unit_id = start_unit.id, end_unit.id
          resource.save!
        end
        # some of these specs redundant, vis-a-vis the resource spec
        it 'returns any resources that match the unit' do
          other_resource = create(:resource, :program => program, :source => 'apple', :start_unit_id => other_unit.id)
          finder = InstructorResourceFinder.new(instructor, program, { :start_unit_id => start_unit.id })
          expect(finder.base_scope).to eq([resource])
        end

        it 'returns any resources that are in the unit range' do
          other_resource = create(:resource, :program => program, :source => 'apple', :start_unit_id => other_unit.id)
          finder = InstructorResourceFinder.new(instructor, program, { :start_unit_id => middle_unit.id })
          expect(finder.base_scope).to eq([resource])
        end
      end
    end

    context 'when we need to filter uploaded resources' do
      it 'returns an resources that are not uploads' do
        finder = InstructorResourceFinder.new(instructor, program)
        expect(finder.base_scope).to eq([resource])
      end

      it 'returns any uploaded resources that are owned by the instructor' do
        resource.uploaded = true
        resource.owner = instructor
        resource.save!
        other_resource = create(:resource, :program => program, :uploaded => true, :owner => build(:instructor))
        finder = InstructorResourceFinder.new(instructor, program)
        expect(finder.base_scope).to eq([resource])
      end
    end

    context 'when a component is provided' do
      let(:resource_component) { create(:resource_component) }

      it 'returns resources filtered by component' do
        resource.update!(resource_component_id: resource_component.id)
        finder = described_class.new(
          instructor,
          program,
          component_id: resource_component.id
        )
        expect(finder.base_scope).to eq([resource])
      end
    end

    # integration tests

  end
end
