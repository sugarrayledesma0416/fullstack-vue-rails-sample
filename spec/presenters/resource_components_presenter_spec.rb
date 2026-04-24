describe ResourceComponentsPresenter do
  let(:program) { create(:program) }
  let(:presenter) { described_class.new(program.id) }
  let(:resource_component) { create(:resource_component, program_id: program.id) }
  let(:component) { ResourceComponent.by_program(program.id) }

  describe '#components' do
    it 'returns the components by program' do
      expect(ResourceComponent).to receive(:by_program).with(program.id)
      presenter.components
    end
  end

  describe '#populate' do
    it 'returns the presenter object' do
      resource_component
      allow(presenter).to receive(:components).and_return([component])
      presenter.components.each do |component|
        expect(component).to receive(:set_display_delete_link)
      end
      expect(presenter.populate).to eq(presenter)
    end
  end
end
