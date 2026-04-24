describe TimeZoneValidator do
  let(:validator) { TimeZoneValidator.new({ :attributes => [:time_zone] }) }
  let(:model) { double("model", :errors => []) }

  before do
    allow(model.errors).to receive(:add)
  end

  describe '#validate' do
    it 'adds an error when the attribute is an invalid time zone' do
      expect(model).to receive(:errors)
      expect(model.errors).to receive(:add).with(:time_zone, 'must be a valid time zone.')
      validator.validate_each(model, :time_zone, 'blah')
    end

    it 'does not add an error when the attribute is a valid time zone' do
      expect(model).not_to receive(:errors)
      validator.validate_each(model, :time_zone, 'Hanoi')
    end

    it 'allows nil' do
      expect(model).not_to receive(:errors)
      validator.validate_each(model, :time_zone, nil)
    end
  end
end
