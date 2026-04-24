RSpec.shared_examples 'a model with enterprise section validation' do
  before { model.valid? }

  context 'when it is an enterprise section' do
    let(:section) { build_stubbed(:enterprise_section) }

    it { expect(model).not_to be_valid }
    it { expect(model.errors[:section]).not_to be_empty }
  end

  context 'when it is not an enterprise section' do
    let(:section) { build_stubbed(:section) }

    it { expect(model).to be_valid }
  end
end
