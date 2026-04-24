describe UserDefinedWord do
  let(:user) { create(:user) }
  let(:lesson) { create(:lesson) }
  let(:program) { create(:program) }
  let(:udw) do
    described_class.new(
      definition: 'a greeting',
      lesson: lesson,
      program: program,
      target: 'hola',
      translation: 'hello',
      user: user
    )
  end

  describe '#validations' do
    it 'requires a program id' do
      udw.program_id = nil
      udw.valid?
      expect(udw.errors.full_messages).to eq(['Program must exist'])
    end

    it 'requires a user id' do
      udw.user_id = nil
      udw.valid?
      expect(udw.errors.full_messages).to eq(['User must exist'])
    end

    it 'requires a lesson id' do
      udw.lesson_id = nil
      udw.valid?
      expect(udw.errors.full_messages).to eq(['Lesson must exist'])
    end

    it 'requires a target' do
      udw.target = nil
      udw.valid?
      expect(udw.errors.full_messages).to eq(['Foreign word is required'])
    end

    it 'requires a non-blank target' do
      udw.target = "\n \t"
      udw.valid?
      expect(udw.errors.full_messages).to eq(['Foreign word is required'])
    end

    it 'requires a translation' do
      udw.translation = nil
      udw.valid?
      expect(udw.errors.full_messages).to eq(['English word is required'])
    end
  end

  describe '.human_attribute_name' do
    it 'returns attribute_key_name as human readable string' do
      human_attribute = described_class.human_attribute_name(:target)

      expect(human_attribute).to eq 'Foreign word'
    end

    it "return 'english word' when attribute_key_name is translation" do
      human_attribute = described_class.human_attribute_name(:translation)

      expect(human_attribute).to eq 'English word'
    end
  end

  describe '.by_unit' do
    it 'returns only words in lessons in the specified unit' do
      unit = create(:unit)
      other_unit = create(:unit)
      lesson = create(:lesson, unit: unit)
      other_lesson = create(:lesson, unit: other_unit)
      udw = create(:user_defined_word, lesson: lesson)
      create(:user_defined_word, lesson: other_lesson)

      expect(described_class.by_unit(unit)).to eq([udw])
    end
  end
end
