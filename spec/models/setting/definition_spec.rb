describe Setting::Definition do
  let(:user) { create(:user) }

  describe '#to_s' do
    it 'returns a string' do
      class SubDef < Setting::Definition; end

      expect(SubDef.to_s).to be_a String
    end

    it 'returns the classname in underscore format' do
      class SubDef < Setting::Definition; end

      expect(SubDef.to_s).to eq('sub_def')
    end

    it 'joins subclasses/submodules with double underscores' do
      class Super
        class SubDef < Setting::Definition; end
      end

      expect(Super::SubDef.to_s).to eq('super__sub_def')
    end

    it 'removes a leading "Setting" from a class hierarchy' do
      class Setting
        class SubDef < Setting::Definition; end
      end

      expect(Setting::SubDef.to_s).to eq('sub_def')
    end
  end

  describe '#get_default' do
    it 'returns the default specified in the definition' do
      class SubDef < Setting::Definition
        default 'here'
      end

      expect(Setting::Definition.get_default(SubDef)).to eq('here')
    end
  end

  describe '#validates_inclusion_of' do
    it 'creates a validation on Setting' do
      class SubDef < Setting::Definition
        validates_inclusion_of :value, in: ['value']
      end

      setting = Setting.new(
        name: 'sub_def',
        value: 'something_else',
        user: user
      )

      expect(setting).not_to be_valid
    end

    it 'creates a validation on Setting specific to that setting' do
      class SubDef < Setting::Definition
        validates_inclusion_of :value, in: ['value']
      end
      class AllValid < Setting::Definition
      end

      setting = Setting.new(
        name: 'all_valid',
        value: 'something_else',
        user: user
      )

      expect(setting).to be_valid
    end

    it 'includes the improper value in the validation message' do
      class ValidationMessageHasValue < Setting::Definition
        validates_inclusion_of :value, in: ['value']
      end

      setting = Setting.new(
        name: 'validation_message_has_value',
        value: 'something_else',
        user: user
      )

      expect(setting).not_to be_valid
      expect(setting.errors[:value].first).to match(/'something_else'/)
    end

    it 'includes the field name in the validation message' do
      class ValidationMessageHasName < Setting::Definition
        validates_inclusion_of :value, in: ['value']
      end

      setting = Setting.new(
        name: 'validation_message_has_name',
        value: 'something_else',
        user: user
      )

      expect(setting).not_to be_valid
      expect(setting.errors[:value].first).to match(/'validation_message_has_name'/)
    end
  end

  describe '#validates_inclusion_in_constants' do
    it 'allows you to use the standard "constants" method to define included values' do
      class ValidationConstants < Setting::Definition
        DEFINED_CONSTANT = 'here'

        validates_inclusion_in_constants
      end

      setting = Setting.new(
        name: 'validation_constants',
        value: 'something_else',
        user: user
      )
      expect(setting).not_to be_valid

      setting = Setting.new(
        name: 'validation_constants',
        value: 'here',
        user: user
      )
      expect(setting).to be_valid
    end
  end

  describe '#validates_numericality_of' do
    it 'does not allow non-numbers' do
      class ValidatesNumericality < Setting::Definition
        validates_numericality_of :value
      end

      setting = Setting.new(
        name: 'validates_numericality',
        value: 'something_else',
        user: user
      )

      expect(setting).not_to be_valid
      expect(setting.errors[:value].first).to match(/must be a number/)
    end
  end

  describe '#sanitize_value' do
    it 'returns the constants value if a constant is defined with the same name' do
      class SanitizeMatch < Setting::Definition
        CONSTANT = 'value'
      end

      expect(SanitizeMatch.sanitize_value(:constant)).to eq('value')
    end

    it 'returns the symbol if it does not map to a constant' do
      class SanitizeMiss < Setting::Definition
        CONSTANT = 'value'
      end

      expect(SanitizeMiss.sanitize_value(:other)).to eq(:other)
    end

    it 'returns the passed in value if it isnt a symbol' do
      class SanitizePassthrough < Setting::Definition; end

      expect(
        SanitizePassthrough.sanitize_value('custom string')
      ).to eq('custom string')
    end
  end

  describe '#from_symbol' do
    it 'returns the class related to the symbol' do
      class SymbolLookup < Setting::Definition; end

      result = Setting::Definition.from_symbol(:symbol_lookup)
      expect(result).to eq(SymbolLookup)
    end

    it 'returns nil for undefined symbols' do
      result = Setting::Definition.from_symbol(:undefined_symbol)
      expect(result).to be_nil
    end
  end
end
