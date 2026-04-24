describe VocabWordUpdater do
  let(:student) { create(:student) }
  let(:lesson) { create(:lesson) }
  let(:program) { create(:program) }

  def update_vocab_word(params)
    described_class.new(student, params).update_vocab_word
  end

  describe '#update_vocab_word' do
    describe 'when given valid params' do
      describe 'when updating a user defined vocab word' do
        let(:vocab_word) do
          create(:vocab_word, user_id: student.id, target_definition: 'old')
        end

        it 'updates the existing vocab word record' do
          vocab_word = create(
            :vocab_word,
            user_id: student.id,
            target_definition: 'old'
          )
          vocab_word_params = {
            default_vocab_word: 0,
            id: vocab_word.id,
            program_id: program.id,
            target_definition: 'new',
            user_id: student.id,
            vocab_program_group_id: 1
          }

          updated_word = update_vocab_word(vocab_word_params)

          expect(updated_word).to be_valid
          expect(updated_word.target_definition).to eq('new')
        end

        it 'updates the associated vocab tags records' do
          vocab_word = create(:vocab_word, user_id: student.id)
          vocab_tag = create(:vocab_tag, name: 'tag', vocab_word: vocab_word)
          vocab_tag_to_delete = create(
            :vocab_tag, name: 'delete_me', vocab_word: vocab_word
          )
          vocab_tag_to_delete_2 = create(
            :vocab_tag, name: 'delete_me_2', vocab_word: vocab_word
          )

          vocab_word_params = {
            default_vocab_word: 0,
            id: vocab_word.id,
            vocab_tags_attributes: [
              { id: vocab_tag.id, name: 'updated_tag' },
              { id: vocab_tag_to_delete.id, _destroy: 1 },
              { id: vocab_tag_to_delete_2.id, _destroy: 1 }
            ]
          }

          updated_word = update_vocab_word(vocab_word_params)

          expect(updated_word.vocab_tags.first.name).to eq('updated_tag')
          expect(updated_word.vocab_tags).not_to include vocab_tag_to_delete
          expect(updated_word.vocab_tags).not_to include vocab_tag_to_delete_2
        end
      end

      describe 'when updating a default vocab word' do
        let(:default_vocab_word) do
          create(
            :default_vocab_word,
            base_word: 'bar',
            language: 'es',
            target_definition: 'old',
            target_word: 'foo'
          )
        end
        let(:vocab_word_params) do
          {
            default_vocab_word: 1,
            id: default_vocab_word.id,
            language: 'es',
            lesson_id: lesson.id,
            target_definition: 'new',
            target_word: 'foo',
            user_id: nil
          }
        end

        it 'creates a user defined vocab word that is a copy of the default vocab word' do
          updated_word = update_vocab_word(vocab_word_params)

          expect(updated_word.target_definition).to eq('new')
          expect(updated_word.default_vocab_word_id).to eql default_vocab_word.id
        end

        it 'sets vocab tags to a default value of empty' do
          updated_word = update_vocab_word(vocab_word_params)

          expect(updated_word.vocab_tags.to_a).to eql []
        end

        context 'when adding a tag to a default vocab word,' do
          let(:lesson) { create(:lesson) }

          it 'creates a user defined vocab word (copied from default ' \
             'vocab word) and a user defined vocab tag associated ' \
             'with the users word' do
            vocab_word_params = {
              default_vocab_word: 1,
              id: default_vocab_word.id,
              language: 'es',
              target_definition: 'new',
              target_word: 'foo',
              lesson_id: lesson.id,
              user_id: nil,
              vocab_tags_attributes: [ {name: 'new tag'} ]
            }

            updated_word = update_vocab_word(vocab_word_params)
            expect(updated_word.vocab_tags.count).to eql 1
            expect(updated_word.vocab_tags.first.name).to eql 'new tag'
          end
        end
      end
    end
  end

  describe 'when given invalid params' do
    describe 'when updating a user defined vocab word' do
      it 'returns false and stores the errors' do
        vocab_word = create(
          :vocab_word,
          target_definition: 'old',
          user_id: student.id
        )
        vocab_word_params = {
          base_word: '',
          default_vocab_word: 0,
          id: vocab_word.id,
          target_definition: '',
          target_word: '',
          user_id: student.id
        }

        updated_word = update_vocab_word(vocab_word_params)

        expect(updated_word.errors.full_messages).to match_array [
          'Target word, base word, or definition must be entered.'
        ]
      end
    end

    describe 'when updating a default vocab word' do
      it 'returns false and stores the errors' do
        default_vocab_word = create(
          :default_vocab_word,
          base_word: 'bar',
          language: 'es',
          target_definition: 'old',
          target_word: 'foo'
        )
        vocab_word_params = {
          default_vocab_word: 1,
          id: default_vocab_word.id,
          user_id: nil
        }
        updated_word = update_vocab_word(vocab_word_params)

        expect(updated_word.errors.full_messages).to match_array [
          'Language is required',
          'Target word, base word, or definition must be entered.',
          'Lesson must exist'
        ]
      end
    end
  end
end
