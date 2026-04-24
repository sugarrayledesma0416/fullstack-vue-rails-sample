describe VocabWordDeleter do
  let(:student) { create(:student) }

  describe '#delete_vocab_word' do
    describe 'when deleting a user defined vocab word' do
      it 'sets the archived flag on the vocab word record' do
        vocab_word = create(
          :vocab_word,
          user_id: student.id,
          target_definition: 'old'
        )
        VocabWordDeleter.new(student, id: vocab_word.id).delete_vocab_word
        expect(vocab_word.reload.archived).to be_truthy
      end
    end

    describe 'when deleting a default vocab word' do
      it 'copies the default vocab word as a user vocab word with the archived flag set' do
        default_vocab_word = create(
          :default_vocab_word,
          target_word: 'foo',
          language: 'es',
          base_word: 'bar',
          target_definition: 'old'
        )
        VocabWordDeleter.new(
          student,
          id: default_vocab_word.id,
          default_vocab_word: '1'
        ).delete_vocab_word
        vocab_word = VocabWord.where(
          user_id: student.id, target_word: 'foo'
        ).first
        expect(vocab_word.default_vocab_word_id).to eql default_vocab_word.id
        expect(vocab_word.archived).to be_truthy
      end
    end
  end
end
