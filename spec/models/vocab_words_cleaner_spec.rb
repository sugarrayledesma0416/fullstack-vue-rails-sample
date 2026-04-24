describe VocabWordsCleaner do
  let(:program) { create(:vol_program_with_lessons) }

  before do
    program.lessons.each do |lesson|
      create(:default_vocabulary_word, program: program, lesson: lesson)
    end
  end

  describe '.clean' do
    it 'deletes the default vocabulary word records' do
      expect { described_class.clean(program.id, should_delete = true) }.to change(DefaultVocabularyWord, :count).by(-2)
    end

    it 'does not delete default vocabulary word records' do
      expect(described_class.clean(program.id, should_delete = false)).to eq(2)
    end
  end
end
