describe ResourceComponent do
  describe '#components_by_program' do
    it 'returns all components for a given program, if there is a resource ' \
       'for that program' do
      program_1 = build(:program)
      program_2 = build(:program)

      component_1 = create(:resource_component, program: program_1)
      component_2 = create(:resource_component, program: program_2)

      create(:resource, program: program_1, resource_component: component_1)
      create(:resource, program: program_2, resource_component: component_2)

      expect(described_class.components_by_program(program_1)).to eq(
        [component_1]
      )
    end

    it 'returns distinct components' do
      program = create(:program)
      component = create(:resource_component, program: program)
      create(
        :resource,
        program: program,
        resource_component: component
      )
      create(
        :resource,
        program: program,
        resource_component: component
      )

      expect(described_class.components_by_program(program)).to eq([component])
    end
  end

  describe '#<=>' do
    it 'compares resource components by name' do
      resources = %w[Henrique Remy Adam arthur].map do |name|
        create(:resource_component, name: name)
      end
      expect(resources.sort).to eq(
        [
          resources[2],
          resources[0],
          resources[1],
          resources[3]
        ]
      )
    end

    it 'compares resource components by name, prioritizing the name "Other"' do
      resources = %w[Henrique Other Adam other arthur].map do |name|
        create(:resource_component, name: name)
      end
      expect(resources.sort).to eq(
        [
          resources[1],
          resources[2],
          resources[0],
          resources[4],
          resources[3]
        ]
      )
    end
  end
end
